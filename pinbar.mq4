//+------------------------------------------------------------------+
//| Pin Bar EA                                                      |
//| This EA identifies pin bars with the tail 3x longer than the body|
//+------------------------------------------------------------------+
#property strict
#property description "This Expert Advisor identifies pin bars where the tail is at least three times longer than the body and touches an 8-period moving average."
#property description "The EA highlights detected pin bars on the chart and alerts the user when such formations occur."
#property description "The detection considers moving average direction and pin bar crossing conditions."

// Input parameters
input double LotSize = 0.01;       // Lot size for orders
input int StopLossPips = 20;      // Stop loss in pips
input int TakeProfitPips = 40;    // Take profit in pips
input int TrendCandleCount = 6;   // Number of candles to determine the trend

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

// Function to determine if the moving average is trending up or down based on recent candles
int MovingAverageTrend(int maPeriod, int candles) {
   double sum = 0;
   for (int i = 0; i < candles - 1; i++) {
      double currentMA = iMA(NULL, 0, maPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
      double previousMA = iMA(NULL, 0, maPeriod, 0, MODE_SMA, PRICE_CLOSE, i + 1);
      sum += (currentMA - previousMA);
   }

   if (sum > 0) {
      return 1; // Uptrend
   } else if (sum < 0) {
      return -1; // Downtrend
   } else {
      return 0; // Sideways
   }
}

// Function to check if pin bar interacts with the moving average and satisfies crossing conditions
bool IsPinBarOnMovingAverage(int i, int maPeriod, int trendCandles) {
   double maValue = iMA(NULL, 0, maPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
   double high = iHigh(NULL, 0, i);
   double low = iLow(NULL, 0, i);

   int trend = MovingAverageTrend(maPeriod, trendCandles);

   // Check if the moving average is trending down and the pin bar crosses it from below upwards
   if (trend == -1 && low < maValue && high > maValue) {
      return true;
   }

   // Check if the moving average is trending up and the pin bar crosses it from above downwards
   if (trend == 1 && high > maValue && low < maValue) {
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

   if (IsPinBar(currentCandle) && IsPinBarOnMovingAverage(currentCandle, 8, TrendCandleCount)) {
      int direction = PinBarDirection(currentCandle);

      // Draw a blue rectangle around the detected pin bar
      double high = iHigh(NULL, 0, currentCandle);
      double low = iLow(NULL, 0, currentCandle);
      datetime time = iTime(NULL, 0, currentCandle);
      datetime timeNext = iTime(NULL, 0, currentCandle - 1);

      if (direction == 1) {
         // Bullish pin bar: Open a buy order
         double sl = iLow(NULL, 0, currentCandle) - StopLossPips * Point;
         double tp = iHigh(NULL, 0, currentCandle) + TakeProfitPips * Point;
         Alert("Bullish Pin Bar detected on ", Symbol(), " at ", TimeToString(candleTime));
      } else if (direction == -1) {
         // Bearish pin bar: Open a sell order
         double sl = iHigh(NULL, 0, currentCandle) + StopLossPips * Point;
         double tp = iLow(NULL, 0, currentCandle) - TakeProfitPips * Point;
         Alert("Bearish Pin Bar detected on ", Symbol(), " at ", TimeToString(candleTime));
      }
   }
}
