//+------------------------------------------------------------------+
//| Pin Bar EA                                                      |
//| This EA identifies pin bars with the tail 3x longer than the body|
//+------------------------------------------------------------------+
#property strict

// Input parameters
input double LotSize = 0.1;       // Lot size for orders
input int StopLossPips = 20;      // Stop loss in pips
input int TakeProfitPips = 40;    // Take profit in pips

// Function to check if a candle is a pin bar
bool IsPinBar(int i) {
   double open = iOpen(NULL, 0, i);
   double close = iClose(NULL, 0, i);
   double high = iHigh(NULL, 0, i);
   double low = iLow(NULL, 0, i);

   double body = MathAbs(close - open);
   double upper_wick = high - MathMax(open, close);
   double lower_wick = MathMin(open, close) - low;

   // Check if the body is small and one tail is 3x larger
   if (body > 0 && (upper_wick >= 3 * body || lower_wick >= 3 * body)) {
      return true;
   }
   return false;
}

// Function to check pin bar direction
int PinBarDirection(int i) {
   double open = iOpen(NULL, 0, i);
   double close = iClose(NULL, 0, i);
   double high = iHigh(NULL, 0, i);
   double low = iLow(NULL, 0, i);

   double upper_wick = high - MathMax(open, close);
   double lower_wick = MathMin(open, close) - low;

   if (upper_wick > lower_wick) {
      return -1; // Bearish pin bar
   } else if (lower_wick > upper_wick) {
      return 1; // Bullish pin bar
   }
   return 0;
}

// Function to check if pin bar interacts with the moving average
bool IsPinBarOnMovingAverage(int i, int maPeriod) {
   double maValue = iMA(NULL, 0, maPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
   double high = iHigh(NULL, 0, i);
   double low = iLow(NULL, 0, i);

   // Check if the pin bar touches the moving average
   if (low <= maValue && high >= maValue) {
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   Print("Pin Bar EA initialized.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print("Pin Bar EA deinitialized.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   static datetime lastCandleChecked = 0;

   int currentCandle = 1; // Analyze the previous candle
   datetime candleTime = iTime(NULL, 0, currentCandle);

   if (candleTime == lastCandleChecked) return; // Avoid duplicate checks

   lastCandleChecked = candleTime;

   if (IsPinBar(currentCandle) && IsPinBarOnMovingAverage(currentCandle, 8)) {
      int direction = PinBarDirection(currentCandle);

      // Draw a blue rectangle around the detected pin bar
      double high = iHigh(NULL, 0, currentCandle);
      double low = iLow(NULL, 0, currentCandle);
      datetime time = iTime(NULL, 0, currentCandle);
      datetime timeNext = iTime(NULL, 0, currentCandle - 1);
      ObjectCreate(0, "PinBar_" + TimeToString(time, TIME_DATE | TIME_MINUTES), OBJ_RECTANGLE, 0, time, high, timeNext, low);
      ObjectSetInteger(0, "PinBar_" + TimeToString(time, TIME_DATE | TIME_MINUTES), OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, "PinBar_" + TimeToString(time, TIME_DATE | TIME_MINUTES), OBJPROP_STYLE, STYLE_SOLID);

      if (direction == 1) {
         // Bullish pin bar: Open a buy order
         double sl = iLow(NULL, 0, currentCandle) - StopLossPips * Point;
         double tp = iHigh(NULL, 0, currentCandle) + TakeProfitPips * Point;
         // OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, sl, tp, "Pin Bar Buy", 0, 0, Green);
         Alert("Bullish Pin Bar detected on ", Symbol(), " at ", TimeToString(candleTime));
      } else if (direction == -1) {
         // Bearish pin bar: Open a sell order
         double sl = iHigh(NULL, 0, currentCandle) + StopLossPips * Point;
         double tp = iLow(NULL, 0, currentCandle) - TakeProfitPips * Point;
         // OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, sl, tp, "Pin Bar Sell", 0, 0, Red);
         Alert("Bearish Pin Bar detected on ", Symbol(), " at ", TimeToString(candleTime));
      }
   }
}
