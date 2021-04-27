report 18123358 "EOS Send fin. rpt to cust"
{
    Caption = 'Send financial reports to customers (CVS)';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(CustomerLoop; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", Name;

            trigger OnAfterGetRecord();
            var
                Handled: Boolean;
                CustomerList2: List of [code[20]];
                CustomerBasePath: Text;
                FileName: Text;
            begin
                OnBeforeProcessCustomer(CustomerLoop, DataCompression, EnumProcTypePrmtr, Handled);
                if Handled then
                    CurrReport.Skip();

                Window.Update(1, "No.");

                if not CustomerList.Contains("No.") then
                    CurrReport.Skip();

                CustomerBasePath := ServerBasePath + FileManagement.StripNotsupportChrInFileName("No." + ' ' + Name) + '\';
                //EOSLibrary.CreateFolder(CustomerBasePath, TRUE);

                if ProcessLineAgingPrmtr then begin
                    FileName := CustomerBasePath + FileManagement.StripNotsupportChrInFileName(AgingTxt) + '.pdf';
                    CreateLineAging("No.", DetailLevelPrmtr, FileName, CustomerList2);
                end;

                if ProcessColumnAgingPrmtr then begin
                    FileName := CustomerBasePath + FileManagement.StripNotsupportChrInFileName(ColumnAgingTxt) + '.pdf';
                    CreateColumnAging("No.", DetailLevelPrmtr, FileName);
                end;

                SetLanguage("Language Code");
                if ProcessStatementPrmtr then begin
                    FileName := CustomerBasePath + FileManagement.StripNotsupportChrInFileName(StatementTxt) + '.pdf';
                    CreateStatement("No.", DetailLevelPrmtr, FileName);
                end;
                ResetLanguage();

                OnAfterProcessCustomer(CustomerLoop);

                OnManageProcessingTypeForCustomer(CustomerLoop, DataCompression, EnumProcTypePrmtr, ReportSetupPrmtr, Handled);
                if Handled then
                    CurrReport.Skip();
                /*if BatchProcessingType = BatchProcessingType::Send then begin
                    ZipFileName := CreateZipFile(CustomerBasePath);
                    SendZip("No.", ZipFileName);
                    MailProcessed += 1;
                end;*/
            end;

            trigger OnPostDataItem();
            var
                Handled: Boolean;
                ClientFileName: Text;
                ZipFileName: Text;
            begin
                OnPostDataItemCustomer_ManageEnumProcType(EnumProcTypePrmtr, Handled);
                if not Handled then
                    if EnumProcTypePrmtr = EnumProcTypePrmtr::SaveToFile then begin
                        DataCompression.SaveZipArchive(outStreamZip);
                        ZipFileName := CreateZipFile(ServerBasePath);
                        ClientFileName := AgingTxt + '.zip';
                        ZipBlob.CreateInStream(inStreamZip);
                        DownloadFromStream(inStreamZip, SaveAsTxt, '', 'Zip File (*.zip)|*.zip', ClientFileName);
                        DataCompression.CloseZipArchive();
                    end;
            end;

            trigger OnPreDataItem();
            var
                FileName: Text;
            begin
                FileName := ServerBasePath + FileManagement.StripNotsupportChrInFileName(StrSubstNo(SummaryTxt, TableCaption())) + '.pdf';
                if (CreateLineAging('', DetailLevelPrmtr::Customer, FileName, CustomerList) = 0) or (CustomerList.Count = 0) then
                    CurrReport.BREAK();
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(content)
            {
                group(General)
                {
                    Caption = 'General';
                    field(EnumProcType; EnumProcTypePrmtr)
                    {
                        Caption = 'Batch processing type';
                        ApplicationArea = all;

                        trigger OnValidate();
                        begin
                            UpdateRequestPage();
                        end;
                    }
                    group(ReportSetupGroup)
                    {
                        ShowCaption = false;
                        Visible = ReportSetupEnabled;
                        field(ReportSetup; ReportSetupPrmtr)
                        {
                            Caption = 'Report Setup';
                            Enabled = ReportSetupEnabled;
                            ApplicationArea = all;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(tryOpenLookupPage(Text));
                            end;
                        }
                    }
                    field(ProcessLineAging; ProcessLineAgingPrmtr)
                    {
                        Caption = 'Process Line Aging';
                        ApplicationArea = all;

                        trigger OnValidate();
                        begin
                            UpdateRequestPage();
                        end;
                    }
                    field(ProcessColumnAging; ProcessColumnAgingPrmtr)
                    {
                        Caption = 'Process Column Aging';
                        ApplicationArea = all;

                        trigger OnValidate();
                        begin
                            UpdateRequestPage();
                        end;
                    }
                    field(ProcessStatement; ProcessStatementPrmtr)
                    {
                        Caption = 'Process Account Statement';
                        ApplicationArea = all;

                        trigger OnValidate();
                        begin
                            UpdateRequestPage();
                        end;
                    }
                    field(OnlyOpen; OnlyOpenPrmtr)
                    {
                        Caption = 'Only Open Entries';
                        ApplicationArea = all;
                    }
                    field(DetailLevel; DetailLevelPrmtr)
                    {
                        Caption = 'Detail Level';
                        ApplicationArea = all;

                        trigger OnValidate();
                        begin
                            UpdateRequestPage();
                        end;
                    }
                    field(ShowLinkedEntries; ShowLinkedEntriesPrmtr)
                    {
                        Caption = 'Show Linked Entries';
                        Enabled = ShowLinkedEntriesEnabled;
                        ApplicationArea = all;
                    }
                    field(UseSalespersonFromCustomer; UseSalespersonFromCustomerPrmtr)
                    {
                        Caption = 'Use Salesperson from Customer';
                        ApplicationArea = all;
                    }
                    field(PostingDateFilter; PostingDateFilterPrmtr)
                    {
                        Caption = 'Posting Date Filter';
                        ApplicationArea = all;
                    }
                    field(DueDateFilter; DueDateFilterPrmtr)
                    {
                        Caption = 'Due Date Filter';
                        ApplicationArea = all;
                    }
                    field(PaymentMethodFilter; PaymentMethodFilterPrmtr)
                    {
                        Caption = 'Payment Method Filter';
                        TableRelation = "Payment Method";
                        ApplicationArea = all;
                    }
                }
                group("Fälligkeitsregister in Spalte")
                {
                    Caption = 'Column Aging';
                    field(DueDateAt; DueDateAtPrmtr)
                    {
                        Caption = 'Aged As Of';
                        Enabled = ColumnFieldsEnabled;
                        ApplicationArea = all;
                    }
                    field(PeriodLength; PeriodLengthPrmtr)
                    {
                        Caption = 'Period Length';
                        Enabled = ColumnFieldsEnabled;
                        ApplicationArea = all;
                    }
                    field(PrintAmountInLCY; PrintAmountInLCYPrmtr)
                    {
                        Caption = 'Print Amounts in LCY';
                        Enabled = ColumnFieldsEnabled;
                        ApplicationArea = all;
                    }
                    field(ColumnLayout; ColumnLayoutPrmtr)
                    {
                        Caption = 'Column Count due/to be due';
                        Enabled = ColumnFieldsEnabled;
                        ApplicationArea = all;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage();
        begin
            CurrReport.RequestOptionsPage.Caption := CurrReport.RequestOptionsPage.Caption() + SubscriptionMgt.GetLicenseText();
            UpdateRequestPage();
        end;
    }

    labels
    {
    }

    trigger OnPostReport();
    var
        handled: Boolean;
    begin
        Window.Close();
        //lma EOSLibrary.DeleteFolder(ServerBasePath, TRUE, TRUE);

        OnPostReport_OnBeforeManageEnumProcType(EnumProcTypePrmtr, Handled);
        if not Handled then
            case EnumProcTypePrmtr of
                EnumProcTypePrmtr::SaveToFile:
                    Message(CompletedTxt);
            //EnumProcType::Send:
            //    MESSAGE(MailSentTxt, MailProcessed);
            end;
    end;

    trigger OnInitReport()
    begin
        SubscriptionActiv := SubscriptionMgt.GetSubscriptionIsActive();
        DataCompression.CreateZipArchive();
    end;

    trigger OnPreReport();
    begin
        if not SubscriptionActiv then
            Currreport.quit();

        ValidateParameters();

        //lma ServerBasePath := EosLib.GetTempFolderName() + '\CR' + EOSLibrary.GetRandomFileName(8) + '\';
        //lma EOSLibrary.CreateFolder(ServerBasePath, TRUE);

        Window.OPEN('#1#############');
        ZipBlob.CreateOutStream(outStreamZip);
    end;

    var
        Language: Record Language;
        DataCompression: Codeunit "Data Compression";
        FileManagement: Codeunit "File Management";
        SubscriptionMgt: Codeunit "EOS AdvCustVendStat Subscript";
        ZipBlob: Codeunit "Temp Blob";
        Window: Dialog;
        PeriodLengthPrmtr: DateFormula;
        inStreamReport: InStream;
        inStreamZip: InStream;
        outStreamReport: OutStream;
        outStreamZip: OutStream;
        OnlyOpenPrmtr: Boolean;
        PrintAmountInLCYPrmtr: Boolean;
        ProcessColumnAgingPrmtr: Boolean;
        ProcessLineAgingPrmtr: Boolean;
        ProcessStatementPrmtr: Boolean;
        ShowLinkedEntriesPrmtr: Boolean;
        SubscriptionActiv: Boolean;
        UseSalespersonFromCustomerPrmtr: Boolean;
        [InDataSet]
        ColumnFieldsEnabled: Boolean;
        [InDataSet]
        ReportSetupEnabled: Boolean;
        [InDataSet]
        ShowLinkedEntriesEnabled: Boolean;
        CustomerList: List of [code[20]];
        ReportSetupPrmtr: Code[10];
        DueDateAtPrmtr: Date;
        OldLanguage: Integer;
        ColumnLayoutPrmtr: Enum "EOS008 CVD Cust Column setup";
        DetailLevelPrmtr: Enum "EOS008 CVD Cust Detail Level";
        EnumProcTypePrmtr: Enum "EOS AdvCustVendStat BatchProcType";
        DueDateFilterPrmtr: Text;
        PaymentMethodFilterPrmtr: Text;
        PostingDateFilterPrmtr: Text;
        ServerBasePath: Text;
        AgingTxt: Label 'Aging';
        ColumnAgingTxt: Label 'Column Aging';
        CompletedTxt: Label 'Operation completed.';
        DueDateTxt: Label '"Aged As Of"';
        MissingParameterTxt: Label 'You must specify %1.';
        NothingToDoTxt: Label 'You must select at least one report to process.';
        PeriodLengthTxt: Label '"Period Length"';
        SaveAsTxt: Label 'Save as...';
        StatementTxt: Label 'Account statement';
        SummaryTxt: Label 'Summary %1';

    local procedure UpdateRequestPage();
    begin
        ColumnFieldsEnabled := ProcessColumnAgingPrmtr;
        ShowLinkedEntriesEnabled := (DetailLevelPrmtr = DetailLevelPrmtr::Duedates) and
                                    (ProcessLineAgingPrmtr or ProcessStatementPrmtr);

        OnUpdateRequestPage(EnumProcTypePrmtr, ReportSetupEnabled);
        //ReportSetupEnabled := BatchProcessingType = BatchProcessingType::Send;
    end;

    local procedure ValidateParameters();
    begin
        if (not ProcessLineAgingPrmtr) and (not ProcessColumnAgingPrmtr) and (not ProcessStatementPrmtr) then
            Error(NothingToDoTxt);

        if ProcessColumnAgingPrmtr then begin
            if DueDateAtPrmtr = 0D then
                Error(MissingParameterTxt, DueDateTxt);
            if Format(PeriodLengthPrmtr) = '' then
                Error(MissingParameterTxt, PeriodLengthTxt);
        end;
    end;

    [TryFunction]
    local procedure tryOpenLookupPage(var pText: Text)
    var
        FldRef: FieldRef;
        RecRef: RecordRef;
        VarRecord: Variant;
    begin
        RecRef.Open(18122007); // EOS Report Setup
        VarRecord := RecRef;
        if Page.RunModal(0, VarRecord) = Action::LookupOK then begin
            RecRef.GetTable(VarRecord);
            FldRef := RecRef.field(1);
            pText := FldRef.Value();
        end;
    end;

    local procedure CreateLineAging(CustomerNo: Code[20]; DetailLevel2: Enum "EOS008 CVD Cust Detail Level"; FileName: Text; var ProcessedCustomerList: List of [code[20]]): Integer;
    begin
        exit(CreateLineAgingWithCheck(CustomerNo, DetailLevel2, FileName, ProcessedCustomerList, false));
    end;

    local procedure CreateLineAgingWithCheck(CustomerNo: Code[20]; DetailLevel2: Enum "EOS008 CVD Cust Detail Level"; FileName: Text; var ProcessedCustomerList: List of [code[20]]; CheckExistingLinesExecutions: Boolean): Integer;
    // CheckExistingLinesExecutions: if this parameter is true, this means that we check existing lines before inserting the File to the Stream
    var
        AdvCustVendStatSetup: Record "EOS AdvCustVendStat Setup EXT";
        Customer: Record Customer;
        CVSReportParameters: Record "EOS008 CVS Report Parameters";
        SalespersonPurchaser2: Record "Salesperson/Purchaser";
        AdvCustVendStatSharedMem: Codeunit "EOS AdvCustVendStat SharedMem";
        ReportBlob: Codeunit "Temp Blob";
        ReportLineCount: Integer;
    begin
        AdvCustVendStatSetup.Get();
        AdvCustVendStatSetup.InitializeReportID(false);

        if CustomerNo <> '' then begin
            Customer.Get(CustomerNo);
            Customer.SETRECFILTER();
        end else
            Customer.Reset();

        SetGlobalReportParameter(CVSReportParameters);
        CVSReportParameters."Customer Detail Level" := DetailLevel2;
        CVSReportParameters."Customer Vendor Table Filter 1" := CopyStr(Customer.GetView(false), 1, MaxStrLen(CVSReportParameters."Customer Vendor Table Filter 1"));
        CVSReportParameters."SalesPerson Table Filter 1" := CopyStr(SalespersonPurchaser2.GetView(false), 1, MaxStrLen(CVSReportParameters."SalesPerson Table Filter 1"));
        AdvCustVendStatSharedMem.SetReportParameter(CVSReportParameters);

        ReportBlob.CreateOutStream(outStreamReport);
        Report.SaveAs(AdvCustVendStatSetup."Customer Aging Report ID", '', ReportFormat::Pdf, outStreamReport);
        // NPCustomerAging.SaveAs('', ReportFormat::Pdf, outStreamReport);

        AdvCustVendStatSharedMem.GetProcessedCustomerList(ProcessedCustomerList);
        ReportLineCount := AdvCustVendStatSharedMem.GetReportLineCount();

        if CheckExistingLinesExecutions and (ReportLineCount <> 0) and (ProcessedCustomerList.Count <> 0) then begin
            ReportBlob.CreateInStream(inStreamReport);
            DataCompression.AddEntry(inStreamReport, FileName);
        end;

        if (not CheckExistingLinesExecutions) and (ReportLineCount <> 0) and (ProcessedCustomerList.Count <> 0) then begin
            ReportBlob.CreateInStream(inStreamReport);
            DataCompression.AddEntry(inStreamReport, FileName);
        end;

        exit(ReportLineCount);
    end;

    local procedure CreateColumnAging(CustomerNo: Code[20]; DetailLevel2: Enum "EOS008 CVD Cust Detail Level"; FileName: Text): Integer;
    var
        AdvCustVendStatSetup: Record "EOS AdvCustVendStat Setup EXT";
        Customer: Record Customer;
        CVSReportParameters: Record "EOS008 CVS Report Parameters";
        SalespersonPurchaser2: Record "Salesperson/Purchaser";
        AdvCustVendStatSharedMem: Codeunit "EOS AdvCustVendStat SharedMem";
        ReportBlob: Codeunit "Temp Blob";
        handled: Boolean;
    begin
        AdvCustVendStatSetup.Get();
        AdvCustVendStatSetup.InitializeReportID(false);

        Handled := false;
        OnBeforeCreateColumnAging(Customer, EnumProcTypePrmtr, Handled);
        if Handled then
            exit;

        if CustomerNo <> '' then begin
            Customer.Get(CustomerNo);
            Customer.SETRECFILTER();
        end;

        SetGlobalReportParameter(CVSReportParameters);
        CVSReportParameters."Customer Detail Level" := DetailLevel2;
        CVSReportParameters."Customer Vendor Table Filter 1" := CopyStr(Customer.GetView(false), 1, MaxStrLen(CVSReportParameters."Customer Vendor Table Filter 1"));
        CVSReportParameters."SalesPerson Table Filter 1" := CopyStr(SalespersonPurchaser2.GetView(false), 1, MaxStrLen(CVSReportParameters."SalesPerson Table Filter 1"));
        AdvCustVendStatSharedMem.SetReportParameter(CVSReportParameters);

        ReportBlob.CreateOutStream(outStreamReport);
        Report.SaveAs(AdvCustVendStatSetup."Customer Aging Col Report ID", '', ReportFormat::Pdf, outStreamReport);
        ReportBlob.CreateInStream(inStreamReport);
        DataCompression.AddEntry(inStreamReport, FileName);

        exit(AdvCustVendStatSharedMem.GetReportLineCount());
    end;

    local procedure CreateStatement(CustomerNo: Code[20]; DetailLevel2: Enum "EOS008 CVD Cust Detail Level"; FileName: Text);
    var
        AdvCustVendStatSetup: Record "EOS AdvCustVendStat Setup EXT";
        Customer: Record Customer;
        CVSReportParameters: Record "EOS008 CVS Report Parameters";
        AdvCustVendStatSharedMem: Codeunit "EOS AdvCustVendStat SharedMem";
        ReportBlob: Codeunit "Temp Blob";
        handled: Boolean;
    begin
        AdvCustVendStatSetup.Get();
        AdvCustVendStatSetup.InitializeReportID(false);

        Customer.Get(CustomerNo);
        Customer.SETRECFILTER();

        onBeforeCreateStatement(Customer, EnumProcTypePrmtr, handled);
        if handled then exit;

        if CustomerNo <> '' then begin
            Customer.Get(CustomerNo);
            Customer.SETRECFILTER();
        end;

        SetGlobalReportParameter(CVSReportParameters);
        CVSReportParameters."Customer Detail Level" := DetailLevel2;
        CVSReportParameters."Customer Vendor Table Filter 1" := CopyStr(Customer.GetView(false), 1, MaxStrLen(CVSReportParameters."Customer Vendor Table Filter 1"));
        AdvCustVendStatSharedMem.SetReportParameter(CVSReportParameters);

        // Temporary fix, because running the report with this paramter empty caused the NAV crash
        ////ReportParameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="EOS Customer Statement EXT" id="18004255"><Options><Field name="OnlyOpen">false</Field><Field name="ShowLinkedEntries">true</Field><Field name="PostingDateFilter">' + /*Format(DueDateAt, 0, '<Year4>-<Month,2>-<Day,2>') + */'</Field><Field name="DueDateFilter" /><Field name="PaymentMethodFilter" /><Field name="UseSalespersonFromCustomer">true</Field><Field name="SupportedOutputMethod">0</Field><Field name="ChosenOutputMethod">1</Field></Options><DataItems><DataItem name="Customer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="SalespersonFilters">VERSION(1) SORTING(Field1)</DataItem><DataItem name="ReportHeaderValues">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DataProcessing">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CustomerPrint">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Detail">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DueDetail">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
        //ReportParameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="EOS Customer Statement EXT" id="18004255"><Options><Field name="OnlyOpen">false</Field><Field name="ShowLinkedEntries">true</Field><Field name="PostingDateFilter"></Field><Field name="DueDateFilter" /><Field name="PaymentMethodFilter" /><Field name="UseSalespersonFromCustomer">true</Field><Field name="SupportedOutputMethod">0</Field><Field name="ChosenOutputMethod">1</Field></Options><DataItems><DataItem name="Customer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="SalespersonFilters">VERSION(1) SORTING(Field1)</DataItem><DataItem name="ReportHeaderValues">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DataProcessing">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CustomerPrint">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Detail">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DueDetail">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
        ReportBlob.CreateOutStream(outStreamReport);
        Report.SaveAs(AdvCustVendStatSetup."Customer Statement Report ID", '', ReportFormat::Pdf, outStreamReport);
        ReportBlob.CreateInStream(inStreamReport);
        DataCompression.AddEntry(inStreamReport, FileName);
    end;

    local procedure CreateZipFile(BasePath: Text): Text;
    var
    begin
        /*FileCount := EOSLibrary.GenerateFolderFilesList(BasePath, '*.*', TRUE, TRUE);
        if FileCount = 0 then
            exit('');

        ZipFileName := FileManagement2.CreateZipArchiveObject;

        for i := 1 TO FileCount do begin
            FileName := EOSLibrary.GetFilenameFromFileList(i);
            FileManagement2.AddFileToZipArchive(FileName, COPYSTR(FileName, STRLEN(BasePath) + 1));
        end;

        FileManagement2.CloseZipArchive;
        exit(ZipFileName);*/
    end;

    local procedure SendZip(CustomerNo: Code[20]; ZipFileName: Text);

    begin

        // var    
        //PDFQueueMgt: Codeunit 18006528;
        //PDFQueueRequest: Record 18004161;
        /*Customer: Record "Customer";
        TempBlob: Record 99008535;
        WorkFile: File;
        RecRef: RecordRef;
        IStream: InStream;
        OStream: OutStream;
        AllObjWithCaption: Record 2000000058;*/

        /*Customer.GET(CustomerNo);

        RecRef.GETTABLE(Customer);
        RecRef.SETRECFILTER;

        WorkFile.WRITEMODE(false);
        WorkFile.TEXTMODE(false);
        WorkFile.OPEN(ZipFileName);
        WorkFile.CREATEINSTREAM(IStream);
        TempBlob.Blob.CREATEOUTSTREAM(OStream);
        COPYSTREAM(OStream, IStream);
        WorkFile.CLOSE;

        if EVALUATE(AllObjWithCaption."Object ID", CurrReport.OBJECTID(false)) then begin
            AllObjWithCaption."Object Type" := AllObjWithCaption."Object Type"::Report;
            AllObjWithCaption.SETRECFILTER;
            AllObjWithCaption.Find('=');
        end;

        PDFQueueRequest."Custom Attachment" := TempBlob.Blob;
        PDFQueueRequest."Custom Attachment Format" := 'ZIP';
        PDFQueueRequest."Document Description" := COPYSTR(AllObjWithCaption."Object Caption", 1, MAXSTRLEN(PDFQueueRequest."Document Description"));
        PDFQueueMgt.CreatePDFQueueRequest(PDFQueueRequest, RecRef, PDFQueueRequest.Type::Mail, FALSE);

        PDFQueueRequest.VALIDATE("Report Setup Code", ReportSetup);

        PDFQueueRequest.Execute(false);*/
    end;

    local procedure SetGlobalReportParameter(var CVSReportParameters: Record "EOS008 CVS Report Parameters")
    begin
        CVSReportParameters.Init();
        CVSReportParameters."Only Open" := OnlyOpenPrmtr;
        CVSReportParameters."Show Linked Entries" := ShowLinkedEntriesPrmtr;
        CVSReportParameters."Period Length" := PeriodLengthPrmtr;
        CVSReportParameters."Aged As Of" := DueDateAtPrmtr;
        CVSReportParameters."Posting Date Filter" := CopyStr(PostingDateFilterPrmtr, 1, MaxStrLen(CVSReportParameters."Posting Date Filter"));
        CVSReportParameters."Due Date Filter" := CopyStr(DueDateFilterPrmtr, 1, MaxStrLen(CVSReportParameters."Due Date Filter"));
        CVSReportParameters."Payment Method Filter" := CopyStr(PaymentMethodFilterPrmtr, 1, MaxStrLen(CVSReportParameters."Payment Method Filter"));
        CVSReportParameters."Use Salesperson from Customer" := UseSalespersonFromCustomerPrmtr;
    end;

    local procedure SetLanguage(LanguageCode: Code[10]);
    begin
        if Language.Get(LanguageCode) then begin
            OldLanguage := GLOBALLANGUAGE();
            GLOBALLANGUAGE := Language."Windows Language ID";
        end;
    end;

    procedure ResetLanguage();
    begin
        if (GLOBALLANGUAGE() <> OldLanguage) and
           (OldLanguage <> 0)
        then begin
            GLOBALLANGUAGE := OldLanguage;
            OldLanguage := 0;
        end;
    end;

    procedure SetProcessingTypeSave();
    begin
        EnumProcTypePrmtr := EnumProcTypePrmtr::SaveToFile;
    end;

    /*procedure SetProcessingTypeSend();
    begin
        BatchProcessingType := BatchProcessingType::Send;
    end;*/

    /// <summary>Event to manage what to do when the Salesperson/Purchase has been processed</summary>
    /// <parameter name="Customer">the customer processed</parameter>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessCustomer(var Customer: Record Customer)
    begin
    end;

    /// <summary>Event executed OnAfterProcessCustomer, this allows to manage procedures run for each Customer.</summary>
    /// <param name="Customer">Record Customer</param>
    /// <param name="ZipBlob">Record "TempBlob" temporary</param>
    /// <param name="EnumProcType">Enum "EOS AdvCustVendStat BatchProcType"</param>
    /// <param name="Handled">Boolean</param>
    [IntegrationEvent(false, false)]
    local procedure OnManageProcessingTypeForCustomer(var Customer: Record Customer; var ZipArchive: Codeunit "Data Compression"; EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; ReportSetup: Code[20]; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Event exexuted in the onPostDataItem of the Customer data item.
    /// There is possible to execute functions at the end of the run of the data item.
    /// Set Handled a true to disable the handling of EnumProcessType bt the default code.
    /// </summary>
    /// <param name="EnumProcType">Enum "EOS AdvCustVendStat BatchProcType"</param>
    /// <param name="Handled">Boolean</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemCustomer_ManageEnumProcType(EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var Handled: Boolean)
    begin
    end;


    /// <summary>    
    /// Event execute OnPostReport before the standard management of Enum "EOS AdvCustVendStat BatchProcType"
    /// There is possibile to execute something at the end of the report.
    /// </summary>
    /// <param name="EnumProcType">Enum "EOS AdvCustVendStat BatchProcType"</param>
    /// <param name="Handled">Boolean</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostReport_OnBeforeManageEnumProcType(EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var Handled: Boolean)
    begin
    end;

    /// <summary>Event to edit the ReqestPage based on Enum "EOS AdvCustVendStat BatchProcType"</summary>
    /// <param name="EnumProcType">Enum "EOS AdvCustVendStat BatchProcType"</param>
    /// <param name="ReportSetupEnabled">Boolean</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateRequestPage(EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var ReportSetupEnabled: Boolean);
    begin
    end;

    /// <summary>Event raised before the creation of line aging report</summary>
    /// <parameter name="Customer">The customer</parameter>
    [IntegrationEvent(false, false)]
    local procedure onBeforeCreateLineAging(Customer: Record Customer; SingleCustomer: Boolean; EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var handled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateColumnAging(Customer: Record Customer; EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var handled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure onBeforeCreateStatement(Customer: Record Customer; EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var handled: Boolean);
    begin
    end;

    /// <summary>Event executed before the beginning of processing of the customer, this allows to manage procedures run for each Customer.</summary>
    /// <param name="Customer">Record Customer</param>
    /// <param name="ZipBlob">Record "TempBlob" temporary</param>
    /// <param name="outStreamZip"></param>
    /// <param name="EnumProcType">Enum "EOS AdvCustVendStat BatchProcType"</param>
    /// <param name="Handled">Allows you to skip the processing of this customer</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessCustomer(Customer: Record Customer; var ZipArchive: Codeunit "Data Compression"; EnumProcType: Enum "EOS AdvCustVendStat BatchProcType"; var Handled: Boolean)
    begin
    end;
}