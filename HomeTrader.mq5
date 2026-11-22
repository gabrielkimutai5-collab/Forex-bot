//+------------------------------------------------------------------+
//|                                                  HomeTrader.mq5  |
//|  EMA 20/50 + RSI + ATR - Education / Demo Only                   |
//+------------------------------------------------------------------+
#property copyright "HomeTrader"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

input int    FastEMA = 20;
input int    SlowEMA = 50;
input int    RSIPeriod = 14;
input int    ATRPeriod = 14;
input double ATRMultiplier = 2.0;
input double RewardRisk = 2.0;
input double RiskPercent = 0.5;
input int    MaxSpreadPoints = 30;
input ulong  MagicNumber = 20261102;

int hFast, hSlow, hRSI, hATR;
datetime lastBarTime = 0;

int OnInit()
{
   hFast = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI  = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE);
   hATR  = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   IndicatorRelease(hFast);
   IndicatorRelease(hSlow);
   IndicatorRelease(hRSI);
   IndicatorRelease(hATR);
}

bool IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t != lastBarTime)
   {
      lastBarTime = t;
      return true;
   }
   return false;
}

double GetBuffer(int handle, int shift)
{
   double buf[1];
   if(CopyBuffer(handle, 0, shift, 1, buf) <= 0) return 0;
   return buf[0];
}

double CalcLot(double slPoints)
{
   if(slPoints <= 0) return 0.01;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(tickValue <= 0 || tickSize <= 0 || point <= 0) return 0.01;
   double lossPerLot = (slPoints * point / tickSize) * tickValue;
   if(lossPerLot <= 0) return 0.01;
   double lot = riskMoney / lossPerLot;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lot = MathFloor(lot / step) * step;
   lot = MathMax(minLot, MathMin(maxLot, lot));
   return NormalizeDouble(lot, 2);
}

void OnTick()
{
   if(!IsNewBar()) return;
   if(PositionSelect(_Symbol)) return;

   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > MaxSpreadPoints) return;

   double fast0 = GetBuffer(hFast, 1);
   double fast1 = GetBuffer(hFast, 2);
   double slow0 = GetBuffer(hSlow, 1);
   double slow1 = GetBuffer(hSlow, 2);
   double rsi0 = GetBuffer(hRSI, 1);
   double atr = GetBuffer(hATR, 1);
   if(atr <= 0) return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double slDist = atr * ATRMultiplier;
   double slPoints = slDist / point;
   double lot = CalcLot(slPoints);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool buySignal = (fast1 < slow1 && fast0 > slow0 && rsi0 > 50);
   bool sellSignal = (fast1 > slow1 && fast0 < slow0 && rsi0 < 50);

   if(buySignal)
   {
      double sl = ask - slDist;
      double tp = ask + slDist * RewardRisk;
      trade.Buy(lot, _Symbol, ask, sl, tp, "HomeTrader BUY");
   }
   else if(sellSignal)
   {
      double sl = bid + slDist;
      double tp = bid - slDist * RewardRisk;
      trade.Sell(lot, _Symbol, bid, sl, tp, "HomeTrader SELL");
   }
}
//+------------------------------------------------------------------+
