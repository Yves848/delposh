unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, SynEditHighlighter, SynEditCodeFolding, SynHighlighterJSON, SynEdit;

type
  TForm1 = class(TForm)
    SynEdit1: TSynEdit;
    SynJSONSyn1: TSynJSONSyn;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
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
  Buffer: array[0..1023] of Byte;
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
      if not CreateProcess(nil, PChar(CommandLine), nil, nil, True, 0, nil, nil, StartupInfo, ProcessInfo) then
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
begin
  Output := RunPowerShellCommand('Get-WinGetPackage -Source "winget" | ConvertTo-Json');
//Output := RunPowerShellCommand('Get-Process');
  SynEdit1.Text := Output;
end;

end.
