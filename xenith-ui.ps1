# The XENITH VI graphical launcher: the same settings, modes and
# xenith.ini as xenith.cmd, in a window. Windows PowerShell 5.1, WPF,
# nothing to install.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# --- settings ------------------------------------------------------------

$IniPath = Join-Path $PSScriptRoot 'xenith.ini'
$Keys = @('GAME', 'CACHE', 'DATA', 'FIDELITYFX', 'CONSOLE', 'UNIMPLEMENTED',
          'STRICT', 'LOG', 'LOOP_LIMIT', 'SKIP')

function Read-Ini {
    $s = @{}
    foreach ($k in $Keys) { $s[$k] = '' }
    $s['CONSOLE'] = 'series-x'
    $s['UNIMPLEMENTED'] = 'trap'
    $s['STRICT'] = 'off'
    if (Test-Path -LiteralPath $IniPath) {
        foreach ($line in Get-Content -LiteralPath $IniPath) {
            $i = $line.IndexOf('=')
            if ($i -lt 1) { continue }
            $key = $line.Substring(0, $i).Trim()
            if ($s.ContainsKey($key)) { $s[$key] = $line.Substring($i + 1) }
        }
    }
    return $s
}

function Save-Ini {
    param([hashtable]$s)
    $lines = foreach ($k in $Keys) { '{0}={1}' -f $k, $s[$k] }
    Set-Content -LiteralPath $IniPath -Value $lines -Encoding Default
}

# --- window --------------------------------------------------------------

$Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="XENITH VI" Height="720" Width="980"
        WindowStartupLocation="CenterScreen" Background="#0B0D14"
        Foreground="#E7E9F5" FontFamily="Segoe UI" FontSize="13">
  <Grid Margin="14">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
      <Image x:Name="LogoImg" Height="52" Stretch="Uniform"/>
      <StackPanel VerticalAlignment="Bottom" Margin="12,0,0,6">
        <TextBlock Text="XENITH VI" FontSize="22" FontWeight="Bold">
          <TextBlock.Foreground>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
              <GradientStop Color="#4A90E2" Offset="0"/>
              <GradientStop Color="#9013FE" Offset="0.5"/>
              <GradientStop Color="#E614A4" Offset="1"/>
            </LinearGradientBrush>
          </TextBlock.Foreground>
        </TextBlock>
      </StackPanel>
    </StackPanel>
    <GroupBox Grid.Row="1" Header="Settings" Foreground="#9AA1C0" Margin="0,0,0,10">
      <Grid Margin="8">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="110"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="90"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
          <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
          <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Grid.Column="0" Text="Game path" VerticalAlignment="Center"/>
        <TextBox Grid.Row="0" Grid.Column="1" x:Name="TxtGame" Margin="0,3"
                 ToolTip="The title's game_*.exe, from a folder you own (no quotes needed)"/>
        <Button Grid.Row="0" Grid.Column="2" x:Name="BtnGame" Content="Browse..." Margin="6,3,0,3"/>
        <TextBlock Grid.Row="1" Grid.Column="0" Text="Cache location" VerticalAlignment="Center"/>
        <TextBox Grid.Row="1" Grid.Column="1" x:Name="TxtCache" Margin="0,3"
                 ToolTip="VICTORY_CACHE_DIR: shader and image caches. Empty: %LOCALAPPDATA%\victory\cache"/>
        <Button Grid.Row="1" Grid.Column="2" x:Name="BtnCache" Content="Browse..." Margin="6,3,0,3"/>
        <TextBlock Grid.Row="2" Grid.Column="0" Text="Saves location" VerticalAlignment="Center"/>
        <TextBox Grid.Row="2" Grid.Column="1" x:Name="TxtData" Margin="0,3"
                 ToolTip="VICTORY_DATA_DIR: the title's persistent storage (saves, temp). Empty: %LOCALAPPDATA%\victory\data"/>
        <Button Grid.Row="2" Grid.Column="2" x:Name="BtnData" Content="Browse..." Margin="6,3,0,3"/>
        <TextBlock Grid.Row="3" Grid.Column="0" Text="FidelityFX" VerticalAlignment="Center"/>
        <TextBox Grid.Row="3" Grid.Column="1" x:Name="TxtFx" Margin="0,3"
                 ToolTip="VICTORY_FIDELITYFX_DIR: your folder with AMD's FidelityFX PC upscaler DLL; empty: the title's own"/>
        <Button Grid.Row="3" Grid.Column="2" x:Name="BtnFx" Content="Browse..." Margin="6,3,0,3"/>
        <TextBlock Grid.Row="4" Grid.Column="0" Text="Console model" VerticalAlignment="Center"
                   ToolTip="The console the title is told it runs on (device type and memory)"/>
        <ComboBox Grid.Row="4" Grid.Column="1" x:Name="CmbConsole" Margin="0,3" Width="160" HorizontalAlignment="Left">
          <ComboBoxItem Content="series-x"/><ComboBoxItem Content="series-s"/>
        </ComboBox>
        <TextBlock Grid.Row="5" Grid.Column="0" Text="Unimplemented" VerticalAlignment="Center"
                   ToolTip="What imports nothing provides does when called: trap (crash with a report) or zero (return 0)"/>
        <ComboBox Grid.Row="5" Grid.Column="1" x:Name="CmbUnimpl" Margin="0,3" Width="160" HorizontalAlignment="Left">
          <ComboBoxItem Content="trap"/><ComboBoxItem Content="zero"/>
        </ComboBox>
        <CheckBox Grid.Row="6" Grid.Column="0" x:Name="ChkStrict" Content="Strict" Margin="0,3"
                  VerticalAlignment="Center" Foreground="#E7E9F5"/>
        <TextBlock Grid.Row="7" Grid.Column="0" Text="Log file" VerticalAlignment="Center"/>
        <TextBox Grid.Row="7" Grid.Column="1" x:Name="TxtLog" Margin="0,3"
                 ToolTip="--log: the file the run is logged to as well as the console. Empty: a timestamped one in %TEMP%"/>
      </Grid>
    </GroupBox>
    <GroupBox Grid.Row="2" Header="Mode" Foreground="#9AA1C0" Margin="0,0,0,10">
      <StackPanel Margin="8">
        <StackPanel Orientation="Horizontal">
          <RadioButton x:Name="RbPlay" Content="Play" Foreground="#E7E9F5" Margin="0,0,18,0"
                       ToolTip="A plain run, no diagnostics, the release exe when it exists"/>
          <RadioButton x:Name="RbValidate" Content="Debug layer" Foreground="#E7E9F5" Margin="0,0,18,0"
                       ToolTip="The host D3D12 debug layer validates every call"/>
          <RadioButton x:Name="RbCrash" Content="Debug layer + DRED + GPU timing" Foreground="#E7E9F5"
                       IsChecked="True" Margin="0,0,18,0"
                       ToolTip="The durable-evidence run: validation, DRED breadcrumbs, per-list GPU timing"/>
          <RadioButton x:Name="RbCapped" Content="Loops capped" Foreground="#E7E9F5" Margin="0,0,18,0"
                       ToolTip="The crash hunt, plus translated shader loops stopped at --loop-limit (default 4096)"/>
          <RadioButton x:Name="RbSkip" Content="Skip pipelines" Foreground="#E7E9F5"
                       ToolTip="The crash hunt, omitting the draws and dispatches of the listed pipelines"/>
          <TextBlock Text="  Loop limit:" Foreground="#9AA1C0" Margin="14,0,6,0" VerticalAlignment="Center"/>
          <TextBox x:Name="TxtLoop" Width="70" VerticalAlignment="Center"
                   ToolTip="VICTORY_SHADER_LOOP_LIMIT: loops stop after this many iterations (empty: the default 2^20)"/>
          <TextBlock Text="  Skip (hashes):" Foreground="#9AA1C0" Margin="10,0,6,0" VerticalAlignment="Center"/>
          <TextBox x:Name="TxtSkip" Width="230" VerticalAlignment="Center"
                   ToolTip="16-digit shader hashes, comma-separated; their draws and dispatches are omitted"/>
        </StackPanel>
        <TextBlock x:Name="ModeHint" Foreground="#7A80A3" Margin="0,6,0,0" FontSize="11.5"/>
      </StackPanel>
    </GroupBox>
    <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,0,0,8">
      <Button x:Name="BtnRun" Content="Run" Width="120" Height="34" FontWeight="Bold"
              Background="#9013FE" Foreground="White" BorderBrush="#9013FE"/>
      <Button x:Name="BtnStop" Content="Stop" Width="90" Height="34" Margin="10,0,0,0" IsEnabled="False"/>
      <Button x:Name="BtnSave" Content="Save settings" Width="110" Height="34" Margin="10,0,0,0"/>
      <Button x:Name="BtnLog" Content="Open log" Width="90" Height="34" Margin="10,0,0,0"
              ToolTip="Open the run's log (the named one, else the folder of the timestamped ones)"/>
    </StackPanel>
    <TextBox Grid.Row="3" x:Name="LogBox" Margin="0,50,0,0" IsReadOnly="True"
             Background="#121527" BorderBrush="#262C4A" Foreground="#E7E9F5"
             FontFamily="Consolas" VerticalScrollBarVisibility="Auto"
             TextWrapping="NoWrap" AcceptsReturn="True"/>
    <StackPanel Grid.Row="4">
      <TextBlock x:Name="Status" TextWrapping="Wrap" FontSize="11.5" Foreground="#4A90E2"
                 Text="Ready."/>
      <TextBlock Margin="0,4,0,0" TextWrapping="Wrap" FontSize="11.5"
                 Foreground="#7A80A3"
                 Text="Bring your own files: XENITH VI runs a game you already own and supplies nothing of it - no game code, assets or keys. It is a compatibility layer, not affiliated with or endorsed by Microsoft, Rockstar Games or any publisher. A mix of the VIctory runtime and XCL techniques. Code: GPL-3.0-or-later."/>
    </StackPanel>
  </Grid>
</Window>
'@

$Win = [Windows.Markup.XamlReader]::Parse($Xaml)
$S = Read-Ini

# The logo as it is at the top of the website, one level into docs.
$LogoPath = Join-Path $PSScriptRoot 'docs\media\Logo.png'
if (Test-Path -LiteralPath $LogoPath) {
    $logo = New-Object System.Windows.Media.Imaging.BitmapImage
    $logo.BeginInit()
    $logo.UriSource = [Uri]$LogoPath
    $logo.EndInit()
    $Win.FindName('LogoImg').Source = $logo
}

$Win.FindName('TxtGame').Text = $S['GAME']
$Win.FindName('TxtCache').Text = $S['CACHE']
$Win.FindName('TxtData').Text = $S['DATA']
$Win.FindName('TxtFx').Text = $S['FIDELITYFX']
$Win.FindName('TxtLog').Text = $S['LOG']
$Win.FindName('TxtLoop').Text = $S['LOOP_LIMIT']
$Win.FindName('TxtSkip').Text = $S['SKIP']
$Win.FindName('ChkStrict').IsChecked = ($S['STRICT'] -ieq 'on')
$Win.FindName('CmbConsole').SelectedIndex = @('series-x', 'series-s').IndexOf($S['CONSOLE'])
$Win.FindName('CmbUnimpl').SelectedIndex = @('trap', 'zero').IndexOf($S['UNIMPLEMENTED'])

# --- run state -----------------------------------------------------------

$script:Proc = $null
$script:Done = $true
$Buffer = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

function Collect-Settings {
    $S['GAME'] = $Win.FindName('TxtGame').Text.Trim()
    $S['CACHE'] = $Win.FindName('TxtCache').Text.Trim()
    $S['DATA'] = $Win.FindName('TxtData').Text.Trim()
    $S['FIDELITYFX'] = $Win.FindName('TxtFx').Text.Trim()
    $S['LOG'] = $Win.FindName('TxtLog').Text.Trim()
    $S['LOOP_LIMIT'] = $Win.FindName('TxtLoop').Text.Trim()
    $S['SKIP'] = $Win.FindName('TxtSkip').Text.Trim()
    $S['CONSOLE'] = @('series-x', 'series-s')[[Math]::Max(0, $Win.FindName('CmbConsole').SelectedIndex)]
    $S['UNIMPLEMENTED'] = @('trap', 'zero')[[Math]::Max(0, $Win.FindName('CmbUnimpl').SelectedIndex)]
    $S['STRICT'] = $(if ($Win.FindName('ChkStrict').IsChecked) { 'on' } else { 'off' })
}

function Set-Status {
    param([string]$text)
    $Win.FindName('Status').Text = $text
}

function Update-ModeHint {
    $hint = 'The durable-evidence run: validation, DRED breadcrumbs and per-list GPU timing.'
    if ($Win.FindName('RbPlay').IsChecked) {
        $hint = 'A plain run: no diagnostics, and the release exe when it exists.'
    } elseif ($Win.FindName('RbValidate').IsChecked) {
        $hint = 'The host D3D12 debug layer validates every call and reports bad use.'
    } elseif ($Win.FindName('RbCapped').IsChecked) {
        $hint = 'The crash hunt with translated shader loops stopped at the loop limit (empty field: 4096).'
    } elseif ($Win.FindName('RbSkip').IsChecked) {
        $hint = 'The crash hunt that omits the draws and dispatches of the pipelines listed under Skip.'
    }
    $Win.FindName('ModeHint').Text = $hint
}

foreach ($rb in @('RbPlay', 'RbValidate', 'RbCrash', 'RbCapped', 'RbSkip')) {
    $Win.FindName($rb).Add_Checked({ Update-ModeHint })
    $Win.FindName($rb).Add_Unchecked({ Update-ModeHint })
}
Update-ModeHint

$Win.FindName('BtnLog').Add_Click({
    $log = $Win.FindName('TxtLog').Text.Trim()
    if ($log -and (Test-Path -LiteralPath $log)) {
        Start-Process notepad.exe $log
    } else {
        Start-Process explorer.exe ([System.IO.Path]::GetTempPath())
    }
})

function Log-Line {
    param([string]$line)
    [void]$Win.FindName('LogBox').AppendText($line + [Environment]::NewLine)
    $Win.FindName('LogBox').ScrollToEnd()
}

function Info-Or-Error {
    param([string]$text)
    [void][System.Windows.MessageBox]::Show($Win, $text, 'XENITH VI')
}

# --- browsing ------------------------------------------------------------

foreach ($pair in @(@('BtnGame', 'TxtGame', 'exe'), @('BtnCache', 'TxtCache', 'dir'),
                    @('BtnData', 'TxtData', 'dir'), @('BtnFx', 'TxtFx', 'dir'))) {
    $btn = $Win.FindName($pair[0])
    $box = $Win.FindName($pair[1])
    $kind = $pair[2]
    $btn.Add_Click({
        if ($kind -eq 'exe') {
            $dlg = New-Object Microsoft.Win32.OpenFileDialog
            $dlg.Filter = 'Executables (*.exe)|*.exe|All files (*.*)|*.*'
            if ($dlg.ShowDialog($Win)) { $box.Text = $dlg.FileName }
        } else {
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $box.Text = $dlg.SelectedPath
            }
        }
    }.GetNewClosure())
}

$Win.FindName('BtnSave').Add_Click({
    Collect-Settings
    Save-Ini $S
    Log-Line 'settings saved to xenith.ini'
})

# --- running -------------------------------------------------------------

function Start-Run {
    Collect-Settings
    Save-Ini $S
    if (-not $S['GAME']) { Info-Or-Error 'Set the game path first (Settings, Game path).'; return }

    $exe = Join-Path $PSScriptRoot 'target\diag\victory.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
        $exe = Join-Path $PSScriptRoot 'target\release\victory.exe'
    }
    if (-not (Test-Path -LiteralPath $exe)) {
        Info-Or-Error ('No victory.exe here. Build first:' + [Environment]::NewLine +
            'cargo build --profile diag -p victory --features diagnostics')
        return
    }

    # The launcher's settings decide the run's paths, fresh every run, as a
    # shell variable from outside cannot: the runtime reads its environment
    # before its config file, and empty values keep the defaults.
    foreach ($n in @('VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR',
                     'VICTORY_FIDELITYFX_DIR', 'VICTORY_D3D12_DEBUG', 'VICTORY_D3D12_DRED',
                     'VICTORY_GPU_TIMING', 'VICTORY_SHADER_LOOP_LIMIT',
                     'VICTORY_SKIP_PIPELINES')) {
        [Environment]::SetEnvironmentVariable($n, $null, 'Process')
    }
    foreach ($pair in @(@('CACHE', 'VICTORY_CACHE_DIR'), @('DATA', 'VICTORY_DATA_DIR'),
                        @('FIDELITYFX', 'VICTORY_FIDELITYFX_DIR'))) {
        if ($S[$pair[0]]) {
            [Environment]::SetEnvironmentVariable($pair[1], $S[$pair[0]], 'Process')
        }
    }

    $argList = New-Object 'System.Collections.Generic.List[string]'
    $argList.Add('run')
    $argList.Add('"{0}"' -f $S['GAME'])
    $argList.Add('--console'); $argList.Add($S['CONSOLE'])
    $argList.Add('--unimplemented'); $argList.Add($S['UNIMPLEMENTED'])
    if ($S['STRICT'] -ieq 'on') { $argList.Add('--strict') }
    $mode = 'crash-hunt'
    if ($Win.FindName('RbPlay').IsChecked) { $mode = 'play' }
    elseif ($Win.FindName('RbValidate').IsChecked) { $mode = 'debug' }
    elseif ($Win.FindName('RbCapped').IsChecked) { $mode = 'capped' }
    elseif ($Win.FindName('RbSkip').IsChecked) { $mode = 'skip' }
    if ($mode -ne 'play') {
        $argList.Add('--debug-layer'); $argList.Add('--dred'); $argList.Add('--gpu-timing')
    }
    $loopLimit = $S['LOOP_LIMIT']
    if ($mode -eq 'capped' -and -not $loopLimit) { $loopLimit = '4096' }
    if ($loopLimit) { $argList.Add('--loop-limit'); $argList.Add($loopLimit) }
    if ($S['SKIP']) { $argList.Add('--skip-pipelines'); $argList.Add($S['SKIP']) }
    $argList.Add('--execute')
    if ($S['LOG']) {
        $argList.Add('--log'); $argList.Add('"{0}"' -f $S['LOG'])
    } else {
        $argList.Add('--log')
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = ($argList -join ' ')
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $Buffer.Clear()
    $script:Done = $false
    $script:Proc = [System.Diagnostics.Process]::Start($psi)
    $script:Proc.EnableRaisingEvents = $true
    $script:Proc.add_OutputDataReceived({ param($o, $e) if ($null -ne $e.Data) { [void]$Buffer.Add($e.Data) } })
    $script:Proc.add_ErrorDataReceived({ param($o, $e) if ($null -ne $e.Data) { [void]$Buffer.Add($e.Data) } })
    $script:Proc.add_Exited({ param($o, $e) $script:Done = $true })
    $script:Proc.BeginOutputReadLine()
    $script:Proc.BeginErrorReadLine()

    $Win.FindName('BtnRun').IsEnabled = $false
    $Win.FindName('BtnStop').IsEnabled = $true
    Log-Line ('run  ' + $S['GAME'])
    Log-Line ('mode ' + $mode)
    Set-Status ('running: ' + $S['GAME'])
}

function Stop-Run {
    $p = $script:Proc
    if ($p -and -not $p.HasExited) {
        $p.Kill()
        Log-Line 'stop requested'
        Set-Status 'stop requested'
    }
}

$Win.FindName('BtnRun').Add_Click({ Start-Run })
$Win.FindName('BtnStop').Add_Click({ Stop-Run })

$Win.Add_Closed({
    $p = $script:Proc
    if ($p -and -not $p.HasExited) { $p.Kill() }
})

# The run's output, drained from the process's threads onto the window's.
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(300)
$Timer.Add_Tick({
    while ($Buffer.Count -gt 0) {
        Log-Line ([string]$Buffer[0])
        $Buffer.RemoveAt(0)
    }
    if ($script:Done) {
        $Timer.Stop()
        $p = $script:Proc
        if ($p) {
            Log-Line ('exited with ' + $p.ExitCode)
            Set-Status ('exited with ' + $p.ExitCode)
        }
        $Win.FindName('BtnRun').IsEnabled = $true
        $Win.FindName('BtnStop').IsEnabled = $false
    }
})
$Timer.Start()

[void]$Win.ShowDialog()
