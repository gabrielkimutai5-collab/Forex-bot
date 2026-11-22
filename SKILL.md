---
name: hometrader-forex-bot
description: MQL5 Expert Advisor for MetaTrader 5. Trades EMA 20/50 crossover confirmed by RSI 50, with ATR-based SL/TP and spread filter. Risk 0.5% per trade. For demo backtesting and education only.
---

# HomeTrader - Forex Bot

## Strategy
- Pair: EURUSD, GBPUSD, USDJPY - Timeframe: M15 / H1 recommended
- BUY: FastEMA 20 crosses ABOVE SlowEMA 50 on closed bar AND RSI > 50
- SELL: FastEMA 20 crosses BELOW SlowEMA 50 on closed bar AND RSI < 50
- Only 1 position at a time, only on new bar

## Risk Management
- RiskPercent = 0.5% of balance per trade
- SL = ATR(14) x 2.0
- TP = SL x 2.0 (RewardRisk = 2.0)
- MaxSpreadPoints = 30 - no trade if spread too high

## Inputs
FastEMA=20, SlowEMA=50, RSIPeriod=14, ATRPeriod=14, ATRMultiplier=2.0, RewardRisk=2.0, RiskPercent=0.5, MaxSpreadPoints=30, MagicNumber=20261102

## How to Install
1. MT5 > File > Open Data Folder > MQL5 > Experts > Paste HomeTrader.mq5
2. Compile in MetaEditor (F7)
3. Drag onto EURUSD M15 chart, Enable Algo Trading

## How to Backtest
1. Strategy Tester (Ctrl+R) > Select HomeTrader
2. Symbol EURUSD, M15, Last 6-12 months, Every tick based on real ticks
3. Check: Max Drawdown < 20%, Profit Factor > 1.2
4. If fails, DO NOT use on live.

## Disclaimer
Education only. Not financial advice. Forex is risky. Always test on demo first. Never trade money you cannot afford to lose.
