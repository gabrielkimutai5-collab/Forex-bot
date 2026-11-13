# Forex-bot
Forex bot-Auto trade smartly
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

input double RiskPercent = 0.5;
input int FastEMA = 20;
input int SlowEMA = 50;
input int RSIPeriod = 14;
input int ATRPeriod = 14;
input double ATRMultiplier = 2.0;
input double RewardRisk = 2.0;
input int MaxSpreadPoints = 30;
input ulong MagicNumber = 20261102;

int fastHandle, slowHandle, rsiHandle, atrHandle;
datetime lastBar = 0;

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);

   fastHandle = iMA(_Symbol,_Period,FastEMA,0,MODE_EMA,PRICE_CLOSE);
   slowHandle = iMA(_Symbol,_Period,SlowEMA,0,MODE_EMA,PRICE_CLOSE);
   rsiHandle  = iRSI(_Symbol,_Period,RSIPeriod,PRICE_CLOSE);
   atrHandle  = iATR(_Symbol,_Period,ATRPeriod);

   if(fastHandle==INVALID_HANDLE || slowHandle==INVALID_HANDLE || rsiHandle==INVALID_HANDLE || atrHandle==INVALID_HANDLE)
      return INIT_FAILED;

   lastBar = iTime(_Symbol,_Period,0);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fastHandle);
   IndicatorRelease(slowHandle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(atrHandle);
}

bool NewBar()
{
   datetime cur = iTime(_Symbol,_Period,0);
   if(cur==lastBar) return false;
   lastBar = cur;
   return true;
}

double CalculateVolume(ENUM_ORDER_TYPE type, double entry, double sl)
{
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100.0;
   double loss = 0;
   if(!OrderCalcProfit(type,_Symbol,1.0,entry,sl,loss)) return 0;
   if(MathAbs(loss) <= 0) return 0;

   double volume = riskMoney / MathAbs(loss);

   double step   = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minVol = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);

   volume = MathFloor(volume/step)*step;
   if(volume < minVol) return 0; // don't violate risk to meet min lot
   volume = MathMin(volume,maxVol);
   
   return volume;
}

void OnTick()
{
   if(!NewBar()) return;
   if(PositionSelect(_Symbol)) return;

   double fast[2], slow[2], rsi[1], atr[1];
   if(CopyBuffer(fastHandle,0,1,2,fast)!=2) return;
   if(CopyBuffer(slowHandle,0,1,2,slow)!=2) return;
   if(CopyBuffer(rsiHandle,0,1,1,rsi)!=1) return;
   if(CopyBuffer(atrHandle,0,1,1,atr)!=1) return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) return;
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if((tick.ask-tick.bid)/point > MaxSpreadPoints) return;
   if(atr[0] <= 0) return;

   double slDist = atr[0]*ATRMultiplier;
   int digits = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   double stopsLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*point;
   if(slDist < stopsLevel) return;

   // BUY: fast crossed ABOVE slow on closed bar
   if(fast[0] > slow[0] && fast[1] <= slow[1] && rsi[0] > 50)
   {
      double sl = NormalizeDouble(tick.ask - slDist, digits);
      double tp = NormalizeDouble(tick.ask + slDist*RewardRisk, digits);
      double vol = CalculateVolume(ORDER_TYPE_BUY, tick.ask, sl);
      if(vol > 0) trade.Buy(vol, _Symbol, 0, sl, tp, "HomeTrader BUY");
   }
   // SELL: fast crossed BELOW slow on closed bar
   else if(fast[0] < slow[0] && fast[1] >= slow[1] && rsi[0] < 50)
   {
      double sl = NormalizeDouble(tick.bid + slDist, digits);
      double tp = NormalizeDouble(tick.bid - slDist*RewardRisk, digits);
      double vol = CalculateVolume(ORDER_TYPE_SELL, tick.bid, sl);
      if(vol > 0) trade.Sell(vol, _Symbol, 0, sl, tp, "HomeTrader SELL");
   }
}
