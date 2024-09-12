unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.JSON.Serializers,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, SynEditHighlighter,
  SynEditCodeFolding, SynHighlighterJSON, SynEdit;

type

  {
    "InstalledVersion": "1.1.12",
    "Name": "NVM for Windows",
    "Id": "CoreyButler.NVMforWindows",
    "IsUpdateAvailable": false,
    "Source": "winget",
    "AvailableVersions": [
    "1.1.12",
    "1.1.11",
    "1.1.10",
    "1.1.9",
    "1.0.1"
    ]
  }
  TPackage = record
    InstalledVersion: string;
    Name: string;
    IsUpdateAvailable: boolean;
    Source: String;
    AvailableVersions: tArray<String>;
  end;

  TForm1 = class(TForm)
    SynEdit1: TSynEdit;
    SynJSONSyn1: TSynJSONSyn;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function RunPowerShellCommand(const ACommand: string): string;

var
  Form1: TForm1;

implementation

function RunPowerShellCommand(const ACommand: string): string;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  SecurityAttributes: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  Buffer: array [0 .. 4095] of ansichar;
  BytesRead: DWORD;
  CommandLine: string;
  OutputStream: TMemoryStream;
  OutputString: TStringList;
begin
  Result := '';
  OutputStream := TMemoryStream.Create;
  OutputString := TStringList.Create;
  try
    // Set up the security attributes struct
    SecurityAttributes.nLength := SizeOf(TSecurityAttributes);
    SecurityAttributes.bInheritHandle := True;
    SecurityAttributes.lpSecurityDescriptor := nil;

    // Create pipes for standard output
    if not CreatePipe(ReadPipe, WritePipe, @SecurityAttributes, 0) then
      RaiseLastOSError;

    try
      // Set up startup info
      ZeroMemory(@StartupInfo, SizeOf(TStartupInfo));
      StartupInfo.cb := SizeOf(TStartupInfo);
      StartupInfo.hStdOutput := WritePipe;
      StartupInfo.hStdError := WritePipe;
      StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_HIDE;

      // Set up the process info struct
      ZeroMemory(@ProcessInfo, SizeOf(TProcessInformation));

      // Command line
      CommandLine := 'pwsh.exe -noprofile -Command ' + ACommand;

      // Create the PowerShell process
      if not CreateProcess(nil, PChar(CommandLine), nil, nil, True, 0, nil, nil,
        StartupInfo, ProcessInfo) then
        RaiseLastOSError;

      // Close the write end of the pipe
      CloseHandle(WritePipe);

      // Read the output from the read end of the pipe
      ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil);
      while (BytesRead > 0) do
      begin
        OutputStream.WriteBuffer(Buffer, BytesRead);
        ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil);
      end;

      // Wait until the process finishes
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

      // Load the memory stream into a string list
      OutputStream.Position := 0;
      OutputString.LoadFromStream(OutputStream);
      Result := OutputString.Text;

    finally
      CloseHandle(ReadPipe);
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end;

  finally
    OutputStream.Free;
    OutputString.Free;
  end;
end;
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  Output: string;
  packages: tArray<TPackage>;
  package: TPackage;
  version : string;
  serializer: TJsonSerializer;
begin
  SynEdit1.lines.Clear;
  Output := RunPowerShellCommand
    ('Get-WinGetPackage -Source "winget" | ConvertTo-Json');
  // SynEdit1.Text := Output;
  try
    serializer := TJsonSerializer.Create;
    packages := serializer.Deserialize < tArray < TPackage >> (Output);
    for package in packages do
    begin
      SynEdit1.lines.Add(package.Name);
      for version in package.AvailableVersions do
        begin
            Synedit1.Lines.add(format('  - %s',[version]));
        end;
    end;
  finally
    serializer.Free;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  Output: String;
  table : tarray<string>;
begin
  SynEdit1.lines.Clear;
  Output := RunPowerShellCommand
    ('@(Get-Module -listavailable -Name Microsoft.WinGet.Client).Length');
//    ('Get-Module -ListAvailable -Name Microsoft.WinGet.Client | convertto-json -asArray -WarningAction SilentlyContinue');

  Synedit1.Lines.text := output;
  
end;

end.
