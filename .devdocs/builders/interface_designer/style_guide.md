# Style Guide: CLI & Messaging

## Color Palette
The following ANSI escape codes are used for standard messaging:

| Type    | Prefix  | Color      | Purpose                     |
|---------|---------|------------|-----------------------------|
| Info    | `===>`  | Blue       | Step progress/Major actions |
| Success | `[ OK ]`| Green      | Operation completion        |
| Error   | `[ ERR ]`| Red        | Failure/Termination         |
| Warning | `[ !! ]`| Yellow     | Caution/Non-fatal issues    |
| Status  | `STATUS:`| Magenta   | State reporting             |

## ASCII Banner
The project uses a custom ASCII banner shown on `start` and `usage`.

```
  _      _   _                
 | |    | | | |               
 | |__  | |_| |__   _____  __ 
 | '_ \ | __| '_ \ / _ \ \/ / 
 | |_) || |_| |_) | (_) >  <  
 |_.__/  \__|_.__/ \___/_/\_\ 
                              
   Bluetooth Audio for FreeBSD 
```

## UI Utility File
Shared functions are located in `src/ui_utils.sh`. Any script requiring output should source this file.
