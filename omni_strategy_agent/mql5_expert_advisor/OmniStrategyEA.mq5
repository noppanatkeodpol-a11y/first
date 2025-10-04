//+------------------------------------------------------------------+
//|                                             OmniStrategyEA.mq5 |
//|                      Copyright 2025, Omni-Strategy-AI-Blueprint |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Omni-Strategy-AI-Blueprint"
#property link      ""
#property version   "1.00"
#property description "Proof-of-Concept EA for Python-MQL5 communication."

// --- Input for the shared directory path. This allows the user to set the path from the EA's properties.
// --- The path should end with a double backslash, e.g., "C:\\Path\\To\\Your\\Project\\omni_strategy_agent\\shared_data\\"
input string InpSharedFolderPath = "omni_strategy_agent\\shared_data\\";

// --- File names
#define MT5_TO_PYTHON_FILE "mt5_to_python.txt"
#define PYTHON_TO_MT5_FILE "python_to_mt5.txt"

// --- Global variables
int file_handle_mt5_out;
int file_handle_python_in;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("OmniStrategyEA: Initializing...");
   Print("Communication files will be stored in Terminal's Common/Files directory.");

   // --- Reset file handles
   file_handle_mt5_out = INVALID_HANDLE;
   file_handle_python_in = INVALID_HANDLE;

   Print("OmniStrategyEA: Initialization complete.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("OmniStrategyEA: Shutting down...");

   // --- Close any open files
   if(file_handle_mt5_out != INVALID_HANDLE)
   {
      FileClose(file_handle_mt5_out);
   }
   if(file_handle_python_in != INVALID_HANDLE)
   {
      FileClose(file_handle_python_in);
   }

   Print("OmniStrategyEA: Shutdown complete.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // --- MQL5 to Python Communication (Write) ---
   string mt5_to_python_path = InpSharedFolderPath + MT5_TO_PYTHON_FILE;

   // --- Open the file to write data to Python. FILE_SHARE_READ allows Python to read it without locking issues.
   file_handle_mt5_out = FileOpen(mt5_to_python_path, FILE_WRITE|FILE_TXT|FILE_SHARE_READ, ';');

   if(file_handle_mt5_out != INVALID_HANDLE)
   {
      // --- Get current market info
      string symbol = Symbol();
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      long volume = (long)SymbolInfoInteger(symbol, SYMBOL_VOLUME);

      // --- Write data as a single line, overwriting the file each time
      FileWrite(file_handle_mt5_out, symbol, TimeCurrent(), bid, ask, volume);

      // --- Close the file
      FileClose(file_handle_mt5_out);
   }
   else
   {
      Print("OmniStrategyEA: Error opening ", MT5_TO_PYTHON_FILE, " for writing. Error code: ", GetLastError());
   }

   // --- Python to MQL5 Communication (Read) ---
   string python_to_mt5_path = InpSharedFolderPath + PYTHON_TO_MT5_FILE;

   // --- Open the file to read commands from Python. FILE_SHARE_WRITE allows Python to write to it.
   file_handle_python_in = FileOpen(python_to_mt5_path, FILE_READ|FILE_TXT|FILE_SHARE_WRITE, ';');

   if(file_handle_python_in != INVALID_HANDLE)
   {
      // --- If the file is not empty, read the command
      if(FileSize(file_handle_python_in) > 0)
      {
         string command = FileReadString(file_handle_python_in);
         Print("OmniStrategyEA: Received command from Python: '", command, "'");
      }

      // --- Close the file
      FileClose(file_handle_python_in);
   }
   // --- Don't print an error if the file doesn't exist, as Python may not have created it yet.
}
//+------------------------------------------------------------------+