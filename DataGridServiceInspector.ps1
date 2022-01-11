Add-Type -AssemblyName PresentationFramework

$xamlFile="C:\Users\fearr\Desktop\ServiceInspectorDataGrid\MainWindow.xaml"
$inputXAML=Get-Content -Path $xamlFile -Raw
$inputXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
[XML]$XAML=$inputXAML

$reader = New-Object System.Xml.XmlNodeReader $XAML
try{
    $form1=[Windows.Markup.XamlReader]::Load($reader)
}catch{
    Write-Host $_.Exception
    throw
}

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try{
        Set-Variable -Name "var_$($_.Name)" -Value $form1.FindName($_.Name) -ErrorAction Stop
    }catch{
        throw
    }
}

$Columns=@(
    'Status'
    'DisplayName'
    'ServiceName'
)

$Services=Get-Service | Select-Object $Columns

$ServiceDataTable=New-Object System.Data.DataTable
[void]$ServiceDataTable.Columns.AddRange($Columns)

foreach($Service in $Services){
    $Entry=@()
    foreach($Column in $Columns){
        $Entry+=$Service.$Column
    }
    [void]$ServiceDataTable.Rows.Add($Entry)
}

$var_dg_services.ItemsSource=$ServiceDataTable.DefaultView
$var_dg_services.IsReadOnly=$true
$var_dg_services.GridLinesVisibility="None"

$var_dg_services.Add_SelectionChanged({
    $var_lbl_servicename.Content=$var_dg_services.SelectedItem.DisplayName
    $var_lbl_servicestatus.Content=$var_dg_services.SelectedItem.Status
})

$var_btn_filter.Add_Click({
    $filter="DisplayName LIKE '$($var_txt_filter.Text)%'"
    $ServiceDataTable.DefaultView.RowFilter=$filter
})


$form1.ShowDialog()