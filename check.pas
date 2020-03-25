unit check;
interface
uses windows,SysUtils, Registry,Regstr, Dialogs;

const FullScreenMode=0; {running default, or called from display-properties-dialog.screensaver-tab.preview-button}
      PreviewMode=1;    {running in preview-window on display-properties-dialog}
      ConfigMode=2;     {called from display-properties-dialog.screensaver-tab.settings-button}
      ConfigRCMode=3;   {called when right-clicked on file}
      PasswordMode=4;   {asking password?}


var SaverMode: integer; {the way the saver is called to start}
    ParamHandle: THandle;   {the Handle passed on command line as parameter}
    PrevActWnd: hWnd;   {last activated window before activating saver}
var {Timer stuff on SaverForm and PreviewForm}
    MouseTicksToIgnore, MouseTicks,
    TimerCounter, TimerTicksPerSecond,
    FramesDropped, FramesPerSecond: integer;

function SetParamHandle(inStr: string): integer;
function CheckSaverMode: integer;



{--- HCore Info defenitions ---}
const OS_STR_WIN={Win32 on }'Windows';
      OS_STR_W31={Win32 on }'Windows 3.1';
      OS_STR_W95={Win32 on }'Windows 95';
      OS_STR_W98={Win32 on }'Windows 98';
      OS_STR_WNT={Win32 on }'Windows NT';

type THCoreInfo = object
       Function UserIDFromWindows: string;
       Function getOS : string;
       Function RunningWin31 : boolean;
       Function RunningWin95 : boolean;
       Function RunningWin98 : boolean;
       Function RunningWinNT : boolean;
       Function getOSVersion : string;
       Function GetProcessor : string;
       function GetWinDir : string;
       function GetSysDir : string;
       function Get3Dfx : boolean;
     end;

var HCoreInfo: THCoreInfo;



{--- registry checking ---}
function SetPwd: boolean;
procedure CheckRegistry;
procedure PutToRegistry(wKey,wItem,wVal: string);


implementation




function SetParamHandle(inStr: string): integer;
begin
  try
    Result:=StrToInt(inStr);
  except
    Result:=0;
  end;
end;


function CheckSaverMode: integer;
var tMode: integer;
    s: string;
begin
  PrevActWnd:=0;
  PrevActWnd:=GetForegroundWindow;
  if ParamCount=0 then
    tMode:=ConfigRCMode
  else begin
    s:=UpperCase(ParamStr(1));
    if Pos('C',s)>0 then begin
      tMode:=ConfigMode;
    end else
    if Pos('A',s)>0 then begin {there must be a window handle}
      tMode:= PasswordMode;
      ParamHandle:=SetParamHandle(ParamStr(2));
    end else
    if Pos('P',s)>0 then begin {there must be a window handle}
      tMode:=PreviewMode;
      ParamHandle:=SetParamHandle(ParamStr(2));
    end else
    if Pos('S',s)>0 then begin
      tMode:=FullScreenMode;
    end else begin
      {start anyway!}
      tMode:=FullScreenMode;
    end;
  end;
  Result:=tMode
end;




{--- HCore Info defenitions ---}

Function THCoreInfo.UserIDFromWindows: string;
Var UserName    : string;
    UserNameLen : Dword;
Begin
  UserNameLen := 255;
  SetLength(userName, UserNameLen);
  If GetUserName(PChar(UserName), UserNameLen) Then
    Result := Copy(UserName,1,UserNameLen - 1)
  Else
    Result := 'unknown';
End;


Function THCoreInfo.getOS : string;
Var OSIRec : TOSVersionInfo;
    S : string;
Begin
  OSIRec.dwOSVersionInfoSize:=SizeOf(OSIRec);
  GetVersionEx(OSIRec);
  case OSIRec.dwPlatformId of
    VER_PLATFORM_WIN32s: S:=OS_STR_W31;
    VER_PLATFORM_WIN32_WINDOWS:
      case OSIRec.dwMinorVersion of
        0..9: S:=OS_STR_W95;
        10: S:=OS_STR_W98;
      end;
    VER_PLATFORM_WIN32_NT: S:=OS_STR_WNT;
  else
    S:=OS_STR_WIN;
  end;
  Result:=S;
End;


Function THCoreInfo.RunningWin31 : boolean;
Begin
  Result:=(getOS=OS_STR_W31);
End;


Function THCoreInfo.RunningWin95 : boolean;
Begin
  Result:=(getOS=OS_STR_W95);
End;


Function THCoreInfo.RunningWin98 : boolean;
Begin
  Result:=(getOS=OS_STR_W98);
End;

Function THCoreInfo.RunningWinNT : boolean;
Begin
  Result:=(getOS=OS_STR_WNT);
End;


Function THCoreInfo.getOSVersion : string;
Var OSIRec : TOSVersionInfo;
    S : string;
    s2 : PChar;
Begin
  OSIRec.dwOSVersionInfoSize:=SizeOf(OSIRec);
  GetVersionEx(OSIRec);
  {OS version}
  S:=IntToStr(OSIRec.dwMajorVersion)+'.'+IntToStr(OSIRec.dwMinorVersion);
  {Buid version}
  case OSIRec.dwPlatformId of
    {VER_PLATFORM_WIN32s}  {Win3.1 no build}
    VER_PLATFORM_WIN32_WINDOWS: S:=S+' Build '+IntToStr(Low(OSIRec.dwBuildNumber));
    VER_PLATFORM_WIN32_NT: S:=S+' Build '+IntToStr(OSIRec.dwBuildNumber);
  end;
  s2:=OSIRec.szCSDVersion;
  if s2<>' ' then S:=S+'    "'+s2+'"';
  Result:=S;
End;


Function THCoreInfo.GetProcessor : string;
Var SysInfo : TSystemInfo;
    S : string;
Begin
  GetSystemInfo(SysInfo);
  S:=IntToStr(SysInfo.dwNumberOfProcessors)+'x ';

  if not RunningWinNT then Begin
    Case SysInfo.dwProcessorType of
      386 : S:=S+'80386';
      486 : S:=S+'80486';
      586 : if SysInfo.wProcessorLevel=5 then S:=S+'Pentium' else
              if SysInfo.wProcessorLevel=6 then S:=S+'P-II' else
                if SysInfo.wProcessorLevel=7 then S:=S+'P-III?';
    else S:=S+'unknown ('+ IntToStr(SysInfo.dwProcessorType) +')';
    End
  End else
//  if RunningWinNT then
    Case SysInfo.wProcessorArchitecture of
      0 {PROCESSOR_ARCHITECTURE_INTEL} : Begin
        case SysInfo.wProcessorLevel of
          3 : S:=S+'80386';
          4 : S:=S+'80486';
          5 : S:=S+'Pentium';
          6 : S:=S+'P-II';
          7 : S:=S+'P-III';
          15 : S:=S+'P-IV';
        end;
      End;
      1 {PROCESSOR_ARCHITECTURE_MIPS} : Begin
        case SysInfo.wProcessorLevel of
          4 : S:=S+'MIPS R4000';
        end;
      End;
      2 {PROCESSOR_ARCHITECTURE_ALPHA} : Begin
        case SysInfo.wProcessorLevel of
          21064 : S:=S+'Alpha 21064';
          21066 : S:=S+'Alpha 21066';
          21164 : S:=S+'Alpha 21164';
        end;
      End;
      3 {PROCESSOR_ARCHITECTURE_PPC} : Begin
        case SysInfo.wProcessorLevel of
          1  : S:=S+'PPC 601';
          3  : S:=S+'PPC 603';
          4  : S:=S+'PPC 604';
          6  : S:=S+'PPC 603+';
          9  : S:=S+'PPC 604+';
          20 : S:=S+'PPC 620';
        end;
      End;
      ELSE S:=S+'unknown';
    End;

  {$UNDEF TESTING}
  {$IFDEF TESTING}
    form1.memo1.lines.add('=========================');
    form1.memo1.lines.add('proc_type='+IntToStr(SysInfo.dwProcessorType));
    form1.memo1.lines.add('proc_level='+IntToStr(SysInfo.wProcessorLevel));
    form1.memo1.lines.add('proc_revision='+IntToStr(SysInfo.wProcessorRevision));
    form1.memo1.lines.add('proc_architecture='+IntToStr(SysInfo.wProcessorArchitecture));
    form1.memo1.lines.add('=========================');
  {$ENDIF}

  Result:=S
End;


function THCoreInfo.GetWinDir : string;
var s: string;
    iLength: Integer;
begin
  iLength:=MAX_PATH;
  setLength(s,iLength);
  iLength:=GetWindowsDirectory(PChar(s),iLength);
  setLength(s,iLength);
  if s[iLength]<>'\' then s:=s+'\';
  Result:=s
end;


function THCoreInfo.GetSysDir : string;
var s: string;
    iLength: Integer;
begin
  iLength:=MAX_PATH;
  setLength(s,iLength);
  iLength:=GetSystemDirectory(PChar(s),iLength);
  setLength(s,iLength);
  if s[iLength]<>'\' then s:=s+'\';
  Result:=s
end;


function THCoreInfo.Get3Dfx : boolean;
Var DriverSelect: HMODULE;
    BRet : Longword;
    NrOfBoards: integer;
    NoNoQuit: boolean;
begin
  NoNoQuit:=false;
  {-CHECK OF GLIDE 3 WEL IS GEINSTALLEERD-}
  DriverSelect:=LoadLibrary('Glide2x.dll');
  if (DriverSelect=0) then begin //'Error:  Glide2 not installed.'
    NoNoQuit:=true;
    DriverSelect:=LoadLibrary('Glide3x.dll');
    if (DriverSelect<>0) then NoNoQuit:=false;
  end;
  if DriverSelect<>0 then FreeLibrary(DriverSelect);

(*!!!!DEBUG -this code needs glide.dcu & d3dfx.dcu!
  if not NoNoQuit then begin
   {-CHECK OF TENMINSTE 1 3Dfx KAART IS GEINSTALLEERD-}
    BRet:=grGet(GR_NUM_BOARDS,SizeOf(NrOfBoards),@NrOfBoards);
    NoNoQuit:=(BRet=0);
  end;
*)
  Result:=(not NoNoQuit);
end;

{==============================================================}

{--- sets the password---}
function SetPwd: boolean;
var hLib: THandle;
    P: function (a : PChar; ParentHandle : THandle; b, c : Integer) : Integer; stdcall;
    SysDir: String;
begin
  result := true;
  if HCoreInfo.RunningWinNT then exit;  //not completely working right now....
  SysDir:=HCoreInfo.GetSysDir;
  hLib:=LoadLibrary(PChar(SysDir+'MPR.DLL'));
  if hLib<>0 then begin
    P:=GetProcAddress(hLib,'PwdChangePasswordA');
    if assigned(P) then
      P('SCRSAVE', ParamHandle, 0, 0);
    FreeLibrary(hLib);
  end;
  result:=(hLib<>0) and assigned(P);
end;



{=== Registry things ====================================}

procedure CheckRegistry;
var TheReg: TRegistry;
    KeyName: String;
begin
  TheReg := TRegistry.Create;
  try
    {Check AppPath setting, update if necessary}
    TheReg.RootKey := HKEY_LOCAL_MACHINE;
    KeyName:='Software\HCore\ScreenSaver\Waves';
    {set the current key}
    if TheReg.OpenKey(KeyName, false) then begin
      if (TheReg.ReadString('3Dfx swapped')='1') then
        begin end;
      TheReg.CloseKey;
    end;
  finally
    TheReg.Free;
  end;
end;


procedure PutToRegistry(wKey,wItem,wVal: string);
var TheReg: TRegistry;
begin
  TheReg := TRegistry.Create;
  try
    {Check settings, update if necessary}
    TheReg.RootKey := HKEY_LOCAL_MACHINE;
    if wKey='' then wKey:='Software\HCore\ScreenSaver\Waves';
    if wItem='' then wItem:='3Dfx swapped';
    if wVal='' then wVal:='0';
    {set the current key; create if needed}
    if TheReg.OpenKey(wKey, True) then begin
      TheReg.WriteString(wItem,wVal);
      TheReg.CloseKey;
    end;
  finally
    TheReg.Free;
  end;
end;


initialization
  SaverMode:=CheckSaverMode;
end.
