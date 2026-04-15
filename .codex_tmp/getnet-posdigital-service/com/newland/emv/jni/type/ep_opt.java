package com.newland.emv.jni.type;

public class ep_opt
{
    public byte		ucTransType;//in
    public int		emSeqTo;//in
    public int		emSeqStart;//in
    public int		nRequestAmt;//in
    public byte		ucCardNo;//in
    public byte		ucRestart;//in
    public int		nForceOnlineEnable;  //in              
    public int		nAccountTypeEnable;  //in           
    public byte[]	pusOnlinePin = new byte[12];//out
    public byte[]	pusIssScriptRes = new byte[100];//out
    public int		nIssSresLen;//out
    public int		nAdviceReq;//out
    public int		nForceAcceptSupported;//out
    public int		nSignatureReq;//out
    public byte[]	pusAuthRespCode = new byte[2];//in     
    public byte[]	pusField55 = new byte[256];//in     
    public int		nField55Len;//in     
    public int		nOnlineResult;//in     
    public int		nTransRet;//out
    
    /*********************Entry Point Data***************************/
	/*****User Interface Request Data --DF8116 Len=23*****/
    public byte		_UI_message_id;//out
    public byte		_UI_status;//out
    public byte[]	_UI_hold_time = new byte[3];//out
    public byte		_UI_language_len;//out
    public byte[]	_UI_language_preference = new byte[8];//out
    public byte		_UI_value_qualifier;//out
    public byte[]	_UI_value = new byte[6];//out
    public byte[]	_UI_currency_code = new byte[2];//out
    
  	/*****Outcome Parameter Set --DF8129 maybe can use op_set[8]*****/
    public byte		_OP_status;//out
    public byte		_OP_start;//out
    public byte		_OP_online_response_data;//out
    public byte		_OP_cvm;//out
    public byte		_OP_ui_request_on_outcome_present;//out
    public byte		_OP_ui_request_on_restart_present;//out
    public byte		_OP_data_record_present;//out
    public byte		_OP_discretionary_data_present;//out
    public byte		_OP_receipt;//out
    public byte		_OP_alternate_interface_preference;//out
    public byte		_OP_field_off_request;//out
    public byte		_OP_removal_timeout;//out
    
    /*****'FF8106'  10  Discretionary Data 'DF8115'  6  Error Indication  *****/
    public byte		_ER_L1_indication;//out
    public byte		_ER_L2_indication;//out
    public byte		_ER_L3_indication;//out
    public byte		_ER_SW1;//out
    public byte		_ER_SW2;//out
    public byte		_ER_MSG_ON_ERROR;//out
    
    /**paywave for refund transaction request AAC. TC-0X40 ARQC-0X80 AC-OTHER*/
    public byte		_refund_request_aac;//in
    /**control bits. 0x01 = CB implementation of PSE with selection of kernel based on DF61 if 9F2A is missing*/
    public byte     ucCtrl;//in
    /** rupay used, whether the force online option opened */
    public byte 	ucForceBypssPinEnable;//in
	public byte     ucRupayTerEnviron;//in
    public byte[]	_rfu = new byte[6];

    
}

