package com.newland.emv.jni.type;

public class EmvConst {

	/** AID Operation type */

	/** delete a AID */
	public final static int AID_RMV = (0x01);
	/** update a AID(If not exist,add one) */
	public final static int AID_UPT = (0x02);
	/** get a AID */
	public final static int AID_GET = (0x10);
	/** Read terminal configuration */
	public final static int AID_CONFIG_R = (0x20);
	/** Write terminal configuration  */
	public final static int AID_CONFIG_W = (0x40);
	/** clear all AID(Does not affect terminal configuration) */
	public final static int AID_CLR = (0x80);
	/** clear all AID */
	public final static int AID_RESET = (0x04);
	

	/** CAPK Operation type */
	
	/** delete a CAPK */
	public static final int CAPK_RMV = (0x01);
	/** update a CAPK(If not exist,add one) */
	public static final int CAPK_UPT = (0x02);
	/** CAPK Deactivation */
	public static final int CAPK_DIS = (0x04);
	/** CAPK Activation */
	public static final int CAPK_ENB = (0x08);
	/** get a CAPK */
	public static final int CAPK_GET = (0x10);
	/** clear all CAPK */
	public static final int CAPK_CLR = (0x20);

	
	/** CARDBLACK/CERTBLACK Operation type */
	
	/** delete */
	public static final int STRUCT_DEL = (0x01);
	/** update(If not exist,add one) */
	public static final int STRUCT_UPT = (0x02);
	/** GET */
	public static final int STRUCT_GET = (0x04);
	/** clear all */
	public static final int STRUCT_CLR = (0x08);

	
	/*
	 * emvparam._status Identify the category of the network test project, 
	 * the implementation of the transaction, must be assigned to identify 
	 * the type of test transactions in China using the default PBOC2_ENB, 
	 * no special requirements set 0
	 */
	/** BCTC */
	public final static int BCTC_TEST_ENB = (0x01);
	/** PBOC */
	public final static int PBOC2_ENB = (0x02);
	/** visa */
	public final static int VISA_ENB = (0x04);
	/** master card */
	public final static int MASTERCARD_ENB = (0x08);
	/** jcb */
	public final static int JCB_ENB = (0x10);
	/** amex */
	public final static int AMEX_ENB = (0x20);
	/** QUICS */
	public final static int BCTC_QUICS_ENB = (0x40);
	/** Discover */
	public final static int DISCOVER_ENB = (0x80);
	/**pure(mccs mada)*/
	public final static int PURE_ENB = (0x81);  
	public final static int MCCS_ENB = PURE_ENB;      
	/**entrypoint certification*/
	public final static int ENTRYPOINT_TEST_ENB = (0x82);       
	/**interac*/
	public final static int INTERAC_ENB = (0x84);        
	/**Rupay*/
	public final static int RUPAY_ENB = (0x88);        

	/********************************** emvparam._ics ICS ************************************************/
	/*
	 * AS : Application Selection Macro: AS_Support_PSE : Support PSE selection
	 * method AS_Support_CardHolder_Confirm : Support Cardholder confirmation
	 * AS_Support_Prefferd_Order : Have a preferred order of displaying
	 * applications AS_Support_Partial_AID : Does the terminal perform partial
	 * AID selection AS_Support_Multi_Language : Does the terminal have multi
	 * language support AS_Support_Common_Charset : Does the terminal support
	 * Common Character Set as defined in "Annex B table 20 Book 4"
	 * 
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int AS_Support_PSE = (0x0080);
	public static final int AS_Support_CardHolder_Confirm = (0x0040);
	public static final int AS_Support_Preferred_Order = (0x0020);
	public static final int AS_Support_Partial_AID = (0x0010);
	public static final int AS_Support_Multi_Language = (0x0008);
	public static final int AS_Support_Common_Charset = (0x0004);

	/*
	 * DA : Data Authentication IPKC : Issuer Public Key Certificate CAPK :
	 * Certification Authority Public Key Macro: DA_Support_IPKC_Revoc_Check :
	 * During DA, does the terminal check the revocation of IPKC
	 * DA_Support_Default_DDOL : Does the terminal contain a default DDOL
	 * DA_Support_CAPKLoad_Fail_Action : Is operation action required when
	 * loading CAPK fails DA_Support_CAPK_Checksum : Is CAPK verified with CAPK
	 * checksum
	 * 
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int DA_Support_IPKC_Revoc_Check = (0x0180);
	public static final int DA_Support_Default_DDOL = (0x0140);
	public static final int DA_Support_CAPKLoad_Fail_Action = (0x0120);
	public static final int DA_Support_CAPK_Checksum = (0x0110);

	/*
	 * CV : Cardholder Verification CVM : Cardholder Verification Methods Macro:
	 * CV_Support_Bypass_PIN : Terminal supports bypass PIN entry
	 * CV_Support_PIN_Try_Counter : Terminal supports Get Data for PIN Try
	 * Counter CV_Support_Fail_CVM : Terminal supports Fail CVM
	 * CV_Support_Amounts_before_CVM : Are amounts known before CVM processing
	 * 
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int CV_Support_Bypass_PIN = (0x0280);
	public static final int CV_Support_PIN_Try_Counter = (0x0240);
	public static final int CV_Support_Fail_CVM = (0x0220);
	public static final int CV_Support_Amounts_before_CVM = (0x0210);
	public static final int CV_Support_Bypass_ALL_PIN = (0x0208);

	/*
	 * TRM : Terminal Risk Management Macro: TRM_Support_FloorLimit : Floor
	 * Limit Checking, Mandatory for terminal with offline capability
	 * TRM_Support_RandomSelect : Random Transaction Selections, Mandatory for
	 * offline terminal with online capability, except when cardholder
	 * controlled TRM_Support_VelocityCheck : Velocity checking, Mandatory for
	 * for terminal with offline capability TRM_Support_TransLog : Support
	 * transaction log TRM_Support_ExceptionFile : Support exception file
	 * TRM_Support_AIPBased : Performance of TRM based on AIP setting
	 * TRM_Use_EMV_LogPolicy : EMV has a different log policy with PBOC2, marked
	 * here
	 * 
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int TRM_Support_FloorLimit = (0x0380);
	public static final int TRM_Support_RandomSelect = (0x0340);
	public static final int TRM_Support_VelocityCheck = (0x0320);
	public static final int TRM_Support_TransLog = (0x0310);
	public static final int TRM_Support_ExceptionFile = (0x0308);
	public static final int TRM_Support_AIPBased = (0x0304);
	public static final int TRM_Use_EMV_LogPolicy = (0x0302);

	/*
	 * TAA : Terminal Action Analysis (x); : the var of struct STEMVCONFIG TAC :
	 * Terminal Action Codes DAC : Default Action Codes Macro: TAA_Support_TAC :
	 * Does the terminal support Terminal Action Codes
	 * TAA_Support_DAC_before_1GenAC : Does the terminal process DAC prior to
	 * first GenAC TAA_Support_DAC_after_1GenAC : Does the terminal process DAC
	 * after first GenAC TAA_Support_Skip_DAC_OnlineFail : Does the terminal
	 * skip DAC processing and automatically request an AAC when unable to go
	 * online TAA_Support_DAC_OnlineFail : Does the terminal process DAC as
	 * normal when unable to go online TAA_Support_CDAFail_Detected : Device
	 * capable of detecting CDA Failure before TAA
	 * TAA_Support_CDA_Always_in_ARQC : CDA always requested in a first Gen AC,
	 * ARQC request TAA_Support_CDA_Never_in_ARQC : CDA never requested in a
	 * first Gen AC, ARQC request TAA_Support_CDA_Alawys_in_2TC : CDA always
	 * requested in a second Gen AC when successful host response is received,
	 * with TC request TAA_Support_CDA_Never_in_2TC : CDA never requested in a
	 * second Gen AC when successful host response is received, with TC request
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int TAA_Support_TAC = (0x0480);
	public static final int TAA_Support_DAC_before_1GenAC = (0x0440);
	public static final int TAA_Support_DAC_after_1GenAC = (0x0420);
	public static final int TAA_Support_Skip_DAC_OnlineFail = (0x0410);
	public static final int TAA_Support_DAC_OnlineFail = (0x0408);
	public static final int TAA_Support_CDAFail_Detected = (0x0404);
	public static final int TAA_Support_CDA_Always_in_ARQC = (0x0402);
	public static final int TAA_Support_CDA_Alawys_in_2TC = (0x0401);

	/*
	 * CP : Completion Process (x); : the var of struct STEMVCONFIG Macro:
	 * CP_Support_Force_Online : Transaction forced Online capability
	 * CP_Support_Force_Accept : Transaction forced Acceptance capability
	 * CP_Support_Advices : Does the terminal support advices
	 * CP_Support_Issuer_VoiceRef : Does the terminal support Issuer Initiated
	 * Voice Referrals CP_Support_Batch_Data_Capture : Does the terminal support
	 * Batch Data Capture CP_Support_Online_Data_capture : Does the terminal
	 * support Online Data Capture CP_Support_Default_TDOL : Does the terminal
	 * support a default TDOL
	 * 
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int CP_Support_Force_Online = (0x0580);
	public static final int CP_Support_Force_Accept = (0x0540);
	public static final int CP_Support_Advices = (0x0520);
	public static final int CP_Support_Issuer_VoiceRef = (0x0510);
	public static final int CP_Support_Batch_Data_Capture = (0x0508);
	public static final int CP_Support_Online_Data_capture = (0x0504);
	public static final int CP_Support_Default_TDOL = (0x0502);

	/*
	 * MISC : Miscellaneous (x); : the var of struct emvconfig Macro:
	 * MISC_Support_Account_Select : Does the terminal support account type
	 * selection MISC_Support_ISDL_Greater_than_128 : Is Issuer Script Device
	 * Limit greater than 128 bytes MISC_Support_Internal_Date_Mana : Does the
	 * terminal support internal date management
	 * 
	 * EMV 4.1 ICS Version 3.9 Level2
	 */
	public static final int MISC_Support_Account_Select = (0x0680);
	public static final int MISC_Support_ISDL_Greater_than_128 = (0x0640);
	public static final int MISC_Support_Internal_Date_Mana = (0x0620);
	public static final int MISC_PP_Support_Default_UDOL = (0x0602);    /* default UDOL (paypass only)*/
	public static final int MISC_MISC_PP_Support_MagAppVer = (0x0601);    /* mag stripe application version (paypass only) 

	/**
	 * TC : Terminal Capabilities(emvparam._cap); terminal capability
	 */
	/** Keyboard input card number */
	public static final int TC_Manual_Key_Entry = (0x0080);
	/** Magnetic stripe card */
	public static final int TC_Magnetic_Stripe = (0x0040);
	/** Contact IC card */
	public static final int TC_IC_With_Contacts = (0x0020);
	/** Plaintext PIN verification */
	public static final int TC_Plaintext_PIN = (0x0180);
	/** Online ciphertext PIN verification */
	public static final int TC_Enciphered_PIN_Online = (0x0140);
	/** Signature (paper); */
	public static final int TC_Signature_Paper = (0x0120);
	/** Offline ciphertext PIN verification */
	public static final int TC_Enciphered_PIN_Offline = (0x0110);
	/** NO CVM */
	public static final int TC_No_CVM_Required = (0x0108);
	/** Cardholder certificate */
	public static final int TC_Cardholder_Cert = (0x0101);
	/** Static data authentication(SDA) */
	public static final int TC_SDA = (0x0280);
	/** Dynamic data authentication(DDA) */
	public static final int TC_DDA = (0x0240);
	/** retain card */
	public static final int TC_Card_Capture = (0x0220);
	/** Composite dynamic data authentication(CDA) */
	public static final int TC_CDA = (0x0208);

	/*
	 * ATC : Additional Terminal Capabilities(emvparam._add_cap); Terminal additional capability
	 */
	/** Cash */
	public static final int ATC_Cash = (0x0080);
	/** goods */
	public static final int ATC_Goods = (0x0040);
	/** Services */
	public static final int ATC_Services = (0x0020);
	/** Cashback */
	public static final int ATC_Cashback = (0x0010);
	/** Inquiry */
	public static final int ATC_Inquiry = (0x0008);
	/** Transfer */
	public static final int ATC_Transfer = (0x0004);
	/** Payment */
	public static final int ATC_Payment = (0x0002);
	/** Administrative */
	public static final int ATC_Administrative = (0x0001);
	/** Deposit */
	public static final int ATC_Cash_Deposit = (0x0180);
	/** Numeric_Keys */
	public static final int ATC_Numeric_Keys = (0x0280);
	/** Alphabetic_Special_Keys */
	public static final int ATC_Alphabetic_Special_Keys = (0x0240);
	/** Command_Keys */
	public static final int ATC_Command_Keys = (0x0220);
	/** Function_Keys */
	public static final int ATC_Function_Keys = (0x0210);
	/** Print_Attendant */
	public static final int ATC_Print_Attendant = (0x0380);
	/** Print_Cardholder */
	public static final int ATC_Print_Cardholder = (0x0340);
	/** Display_Attendant */
	public static final int ATC_Display_Attendant = (0x0320);
	/** Display_Cardholder */
	public static final int ATC_Display_Cardholder = (0x0310);
	/** Code_Table_10 */
	public static final int ATC_Code_Table_10 = (0x0302);
	/** Code_Table_9 */
	public static final int ATC_Code_Table_9 = (0x0301);
	/** Code_Table_8 */
	public static final int ATC_Code_Table_8 = (0x0480);
	/**Code_Table_7 */
	public static final int ATC_Code_Table_7 = (0x0440);
	/** Code_Table_6 */
	public static final int ATC_Code_Table_6 = (0x0420);
	/** Code_Table_5 */
	public static final int ATC_Code_Table_5 = (0x0410);
	/** Code_Table_4 */
	public static final int ATC_Code_Table_4 = (0x0408);
	/** Code_Table_3 */
	public static final int ATC_Code_Table_3 = (0x0404);
	/** Code_Table_2 */
	public static final int ATC_Code_Table_2 = (0x0402);
	/** Code_Table_1 */
	public static final int ATC_Code_Table_1 = (0x0401);

	/*
	 * Terminal transaction property 9F66 (emvparam._trans_prop);
	 */
	/** 1:Support contactless magnetic stripe (MSD); */
	public static final int EMV_PROP_MSD = (0x0080);
	/** 1:Support contactless PBOC */
	public static final int EMV_PROP_PBOCCLSS = (0x0040);
	/** 1:Support contactless qPBOC */
	public static final int EMV_PROP_QPBOC = (0x0020);
	/** 1:Support contact PBOC */
	public static final int EMV_PROP_PBOC = (0x0010);
	/** 1:Supports offline only;  0:Online capability */
	public static final int EMV_PROP_OFFLINE_ONLY = (0x0008);
	/** 1:Supports online PIN */
	public static final int EMV_PROP_ONLINEPIN = (0x0004);
	/** 1:Supports Signature */
	public static final int EMV_PROP_SIGNATURE = (0x0002);


	/** Online ciphertext */
	public static final int EMV_PROP_ONLINEAC = (0x0180);
	/** CVM */
	public static final int EMV_PROP_CVM = (0x0140);
	
    /**1:Support Issuer Update Processing*/	
	public static final int EMV_PROP_IUP = (0x0280);
    /**1:Support Consumer Device CVM ( mobile )*/
	public static final int EMV_PROP_CDCVM = (0x0240);
	public static final int EMV_PROP_01VERSUPPORT = (0x0380);

	/** define STEMVOPTION.nRequestAmount :When to enter the amount */
	/** No input amount */
	public static final int EMV_TRANS_REQAMT_NO = (0);
	/** Application selection input */
	public static final int EMV_TRANS_REQAMT_APS = (1);
	/** Data authentication input */
	public static final int EMV_TRANS_REQAMT_DDA = (2);
	/** Pre-processing input */
	public static final int EMV_TRANS_REQAMT_RFPRECESS = (3);

	/*
	 * =========================emv_opt struct=========================================
	 */
	/*
	 * emv_opt._seq_to to control where EMV kernel is running
	 * EMV_PROC_CONTINUE, execute EMV step until end
	 */
	/** Initiate Application */
	public static final int EMV_PROC_TO_APPSEL_INIT = 0;
	/** Read Application Data */
	public static final int EMV_PROC_TO_READAPPDATA = 1;
	/** Data Authentication */
	public static final int EMV_PROC_TO_OFFLINEAUTH = 2;
	/** Processing Restrictions */
	public static final int EMV_PROC_TO_RESTRITCT = 3;
	/** Cardholder Verification */
	public static final int EMV_PROC_TO_CV = 4;
	/** Terminal Risk Management */
	public static final int EMV_PROC_TO_RISKMANA = 5;
	/** Terminal Action Analysis and Card Action Analysis */
	public static final int EMV_PROC_TO_1GENAC = 6;
	/** Script Processing and Completion */
	public static final int EMV_PROC_TO_2GENAC = 7;
	/** execute EMV step until end */
	public static final int EMV_PROC_CONTINUE = 8;

	/** emv_opt._trans_type(trans type); */
	/** GOODS */
	public static final int EMV_TRANS_GOODS = (0x01);
	/** SERVICES */
	public static final int EMV_TRANS_SERVICES = (0x02);
	/** CASH */
	public static final int EMV_TRANS_CASH = (0x03);
	/** CASHBACK */
	public static final int EMV_TRANS_CASHBACK = (0x04);
	/** INQUIRY */
	public static final int EMV_TRANS_INQUIRY = (0x05);
	/** TRANFER */
	public static final int EMV_TRANS_TRANFER = (0x06);
	/** ADMIN */
	public static final int EMV_TRANS_ADMIN = (0x07);
	/** CASHDEPOSIT */
	public static final int EMV_TRANS_CASHDEPOSIT = (0x08);
	/** PAYMENT */
	public static final int EMV_TRANS_PAYMENT = (0x09);
	
	
	/** Entry Point good servic*/
	public static final int EMV_TRANS_EP_PURCHASE  = 0x00;      
	/** Entry Point cash*/
	public static final int EMV_TRANS_EP_CASH_ADVANCE = 0x01;      
	/**Entry Point */
	public static final int EMV_TRANS_EP_PURCHASE_CASHBACK = 0x09;
	/**Entry Point refund*/
	public static final int EMV_TRANS_EP_REFUND = 0x20;      
	/**manual cash*/
	public static final int EMV_TRANS_EP_MANUAL_CASH = 0x12;      

	
	/** PBOC LOG */
	public static final int EMV_TRANS_PBOCLOG = (0x0A);
	/** SALE */
	public static final int EMV_TRANS_SALE = (0x0B);
	/** PREAUTH */
	public static final int EMV_TRANS_PREAUTH = (0x0C);
	/** BALANCE */
	public static final int EMV_TRANS_BALANCE = (0x0D);
	/** ECLOADLOG */
	public static final int EMV_TRANS_ECLOADLOG = (0x0E);

	/** +++ EC Trans type+++ */
	/** EC goods */
	public static final int EMV_TRANS_EC_GOODS = (EMV_TRANS_GOODS);
	/** EC services */
	public static final int EMV_TRANS_EC_SERVICES = (EMV_TRANS_SERVICES);
	/** EC sale */
	public static final int EMV_TRANS_EC_SALE = (EMV_TRANS_SALE);
	/** EC bindload */
	public static final int EMV_TRANS_EC_BINDLOAD = (0x21);
	/** EC nobindload */
	public static final int EMV_TRANS_EC_NOBINDLOAD = (0x22);
	/** EC cashload */
	public static final int EMV_TRANS_EC_CASHLOAD = (0x23);
	/** EC upload (nonsupport)*/
	public static final int EMV_TRANS_EC_UPLOAD = (0x24);
	/** PBOC LOG */
	public static final int EMV_TRANS_EC_INQUIRE_LOG = (EMV_TRANS_PBOCLOG);
	/** EC BALANCE */
	public static final int EMV_TRANS_EC_INQUIRE_AMOUNT = (0x25);
	/** EC cashload void */
	public static final int EMV_TRANS_EC_CASHLOAD_VOID = (0x26);

	/** +++QPBOC /MSD Trans type+++ */
	public static final int EMV_TRANS_RF_START = (0x30);

	/** QPBOC/MSD goods */
	public static final int EMV_TRANS_RF_GOODS = (EMV_TRANS_GOODS);

	/** QPBOC/MSD services */
	public static final int EMV_TRANS_RF_SERVICES = (EMV_TRANS_SERVICES);

	/** QPBOC/MSD sale */
	public static final int EMV_TRANS_RF_SALE = (EMV_TRANS_SALE);

	/** contactless EC bindload */
	public static final int EMV_TRANS_RF_BINDLOAD = (0x31);

	/** contactless EC nobindload */
	public static final int EMV_TRANS_RF_NOBINDLOAD = (0x32);

	/** contactless EC cashload */
	public static final int EMV_TRANS_RF_CASHLOAD = (0x33);

	/** QPBOC EC BALANCE */
	public static final int EMV_TRANS_RF_INQUIRE_AMOUNT = (0x34);

	/** contactless EC upload (nonsupport) */
	public static final int EMV_TRANS_RF_UPLOAD = (0x35);

	/** contactless EC cashload void */
	public static final int EMV_TRANS_RF_CASHLOAD_VOID = (0x36);

	/** contactless PBOC LOG */
	public static final int EMV_TRANS_RF_PBOCLOG = (0x37);

	/** Card information writing */
	public static final int EMV_TRANS_RF_UPTCARDINFO = (0x38);

	public static final int EMV_TRANS_RF_PBOC_SALE = (0x39);
	/** contactless ECLOAD LOG */
	public static final int EMV_TRANS_RF_ECLOADLOG = (0x40);

	
	/** emv_opt._trans_ret && emv_opt._online_result(transaction Return value); */

	/** Transaction cancelled */
	public static final int EMV_TRANS_CANCEL = (-13);

	/** No card */
	public static final int EMV_TRANS_NOCARD = (-12);

	/** Multiple card */
	public static final int EMV_TRANS_MORECARD = (-11);

	/** fallback */
	public static final int EMV_TRANS_FALLBACK = (-2);

	/** Transaction termination */
	public static final int EMV_TRANS_TERMINATE = (-1);

	/** Transaction acceptance */
	public static final int EMV_TRANS_ACCEPT = (1);

	/** Transaction denial */
	public static final int EMV_TRANS_DENIAL = (2);

	/** Transaction go online */
	public static final int EMV_TRANS_GOONLINE = (3);

	/** 2 Generate AC return AAC */
	public static final int EMV_TRANS_2GAC_AAC = (4);

	/** emv_opt._online_result online failed */
	public static final int EMV_TRANS_ONLINEFAIL = (5);

	/** emv_opt._online_result online succ and Transaction acceptance */
	public static final int EMV_TRANS_ONLINESUCC_ACCEPT = (6);

	/** emv_opt._online_result online succ and Transaction denial */
	public static final int EMV_TRANS_ONLINESUCC_DENIAL = (7);

	/** emv_opt._online_result online succ and Return reference */
	public static final int EMV_TRANS_ONLINESUCC_ISSREF = (8);

	/** get PBOC2 log success */
	public static final int EMV_TRANS_GOON_PBOC2LOG = (9);

	/** get EC LOAD log success */
	public static final int EMV_TRANS_GOON_ECLOADLOG = (10);

	/** get EC BALANCE success */
	public static final int EMV_TRANS_EC_GOON_AMOUNT = (12);

	/** QPBOC approve */
	public static final int EMV_TRANS_QPBOC_ACCEPT = (13);

	/** QPBOC decline */
	public static final int EMV_TRANS_QPBOC_DENIAL = (14);

	/** QPBOC online */
	public static final int EMV_TRANS_QPBOC_GOONLINE = (15);

	/** QPBOC MSD online */
	public static final int EMV_TRANS_MSD_GOONLINE = (16);

	/** qPboc get EC BALANCE success */
	public static final int EMV_TRANS_RF_GOON_AMOUNT = (17);
	/** Please active card*/
	public static final int EMV_TRANS_RF_ACTIVECARD = (18);
	/** select next aid */
	public static final int EMV_TRANS_SLECT_NEXTAID = (19);

	/******************** EMV error code**************** */
	public static final int EMV_ERR_BASE = 0;
	
	
	public static class EntryPointSeq{
	     /**pre_processing */
	    public static final int START_A = 0x00;
	    /**protocol activation*/
	    public static final int START_B = 0x01;           
	    public static final int START_PPSE_SEL = 0x02;
	    /**select the combination*/
	    public static final int START_C = 0x03;            
	    public static final int START_FINAL_APP = 0x04;
	    /**kernel activation*/
	    public static final int START_D = 0x05;           
	    /**outcome processing*/
	    public static final int START_OUTCOME = 0x06;
	    /** Deal with the end of the Entry Point does not require*/
	    public static final int START_END = 0xFF;    
	}

	public static final int UI_MSGID_APPROVED = 0x03;
	public static final int UI_MSGID_DECLINED = 0x07;
	public static final int UI_MSGID_PLEASE_ENTER_YOURE_PIN = 0x09;
	public static final int UI_MSGID_PROCESSING_ERROR = 0x0F;
	public static final int UI_MSGID_REMOVE_CARD = 0x10;
	public static final int UI_MSGID_TRY_AGAIN = 0x11;
	public static final int UI_MSGID_WELCOME = 0x14;
	public static final int UI_MSGID_PRESENT_CARD = 0x15;
	public static final int UI_MSGID_PROCESSING = 0x16;
	public static final int UI_MSGID_CARD_READ_OK = 0x17;
	public static final int UI_MSGID_INSERT_OR_SWIPE_CARD = 0x18;
	public static final int UI_MSGID_PRESENT_ONE_CARD_ONLY = 0x19;
	public static final int UI_MSGID_APPROVED_SIGN = 0x1A; 
	public static final int UI_MSGID_AUTHORISING_PLEASE_WAIT = 0x1B;
	public static final int UI_MSGID_ERROR_OTHER_CARD = 0x1C;
	public static final int UI_MSGID_INSERT_CARD = 0x1D;
	public static final int UI_MSGID_CLEAR_DISPLAY = 0x1E;
	public static final int UI_MSGID_SEE_PHONE = 0x20;
	public static final int UI_MSGID_PRESENT_CARD_AGAIN = 0x21; //try again
	public static final int UI_MSGID_USE_ANOTHER_CARD = 0x22;
	public static final int UI_MSGID_NA = 0xFF;
	
	/***Paypass define Status  *****/
	public static final int UI_STATUS_NOT_READY = 0x00;
	public static final int UI_STATUS_IDLE = 0x01;
	public static final int UI_STATUS_READY_TO_READ = 0x02;
	public static final int UI_STATUS_PROCESSING = 0x03;
	public static final int UI_STATUS_CARD_READ_SUCCESSFULLY = 0x04;
	public static final int UI_STATUS_PROCESSING_ERROR = 0x05;
	public static final int UI_STATUS_STATUS_NA = 0xFF;
	/***Paypass define Value Qualifier   *****/
	public static final int UI_VALUE_QUALIFIER_NONE = 0x00;
	public static final int UI_VALUE_QUALIFIER_AMOUNT = 0x10;
	public static final int UI_VALUE_QUALIFIER_BALANCE = 0x20;

	/***A.1.68 Error Indication   'DF8115'  6 ***/
	public static final int ER_L1_OK = 0x00;
	public static final int ER_L1_TIMEOUT = 0x01;
	public static final int ER_L1_TRANSMISSION = 0x02;
	public static final int ER_L1_PROTOCOL = 0x03;

	public static final int ER_L2_OK = 0x00;
	public static final int ER_L2_CARD_DATA_MISSING = 0x01;
	public static final int ER_L2_CAM_FAILD = 0x02;
	public static final int ER_L2_STATUS_BYTES = 0x03;
	public static final int ER_L2_PARSING_ERROR = 0x04;
	public static final int ER_L2_MAX_LIMIT_EXCEEDED = 0x05;
	public static final int ER_L2_CARD_DATA_ERROR = 0x06;
	public static final int ER_L2_MAGSTRIPE_NOT_SUPPORTED = 0x07;
	public static final int ER_L2_NO_PPSE = 0x08;
	public static final int ER_L2_PPSE_FAULT = 0x09;
	public static final int ER_L2_EMPTY_CANDIDATE_LIST = 0x0A;
	public static final int ER_L2_IDS_READ_ERROR = 0x0B;
	public static final int ER_L2_IDS_WRITE_ERROR = 0x0C;
	public static final int ER_L2_IDS_DATA_ERROR = 0x0D;
	public static final int ER_L2_IDS_NO_MATCHING_AC = 0x0E;
	public static final int ER_L2_TERMINAL_DATA_ERROR = 0x0F;

	public static final int ER_L3_OK = 0x00;
	public static final int ER_L3_TIME_OUT = 0x01;
	public static final int ER_L3_STOP = 0x02;
	public static final int ER_L3_AMOUNT_NOT_PRESENT = 0x03;
	/**A.1.110  Outcome Parameter Set  Tag:  'DF8129' Length:  8 **/
	/*Byte 1 bit8-5 Status*/
	public static final int OP_STATUS_APPROVED = 0x10;
	public static final int OP_STATUS_DECLINED = 0x20;
	public static final int OP_STATUS_ONLINE_REQUEST = 0x30;
	public static final int OP_STATUS_END_APPLICATION = 0x40;
	public static final int OP_STATUS_SELECT_NEXT = 0x50;
	public static final int OP_STATUS_TRY_ANOTHER_INTERFACE = 0x60;
	public static final int OP_STATUS_TRY_AGAIN = 0x70;
	public static final int OP_STATUS_NA = 0xF0;
	/*Byte 2 bit8-5 Start*/
	public static final int OP_START_A = 0x00;
	public static final int OP_START_B = 0x10;
	public static final int OP_START_C = 0x20;
	public static final int OP_START_D = 0x30;
	public static final int OP_START_NA = 0xF0;
	/*Byte 3 bit8-5 Online Response Data*/
	public static final int OP_ONLINE_RESPONSE_DATA_NA = 0xF0;
	/*Byte 4 bit8-5 CVM*/
	public static final int OP_NO_CVM = 0x00;
	public static final int OP_OBTAIN_SIGNATURE = 0x10;
	public static final int OP_ONLINE_PIN = 0x20;
	public static final int OP_CONFIRMATION_CODE_VERIFIED = 0x30;
	public static final int OP_CVM_NA = 0xF0;
	/*Byte 5 bit8-4 */
	public static final int OP_UI_REQUEST_ON_OUTCOME_PRESENT = 0x80; //Mark User Interface Request Data 
	public static final int OP_UI_REQUEST_ON_RESTART_PRESENT = 0x40;
	public static final int OP_DATA_RECORD_PRSENT = 0x20;
	public static final int OP_DISCRETIONARY_DATA_PRESENT = 0x10;
	public static final int OP_RECEIPT = 0x40;// 0:n/a ; 1:YES
	/*Byte 6 bit8-5 Alternate Interface Preference*/
	public static final int OP_ALTERNATE_INTERFACE_PREFERENCE = 0xF0;
	/*Byte 7 bit8-1 Field Off Request*/
	public static final int OP_FIELD_OFF_REQUEST = 0xFF; // FF:N/A ; Other value:Hold time in units of 100ms
	/*Byte 8 bit8-1 Removal Timeout*/
	public static final int OP_REMOVAL_TIMEOUT = 0xFF;

	

	/*  ******** RF Transaction Return value  and emv_opt._trans_ret ******** */
	public static final int EMV_TRANS_RF_TERMINATE = -1;        /*Transaction terminate*/
	public static final int EMV_TRANS_RF_MCHIP_ACCEPT = 11;        /*RF M/CHIP transaction succ */
	public static final int EMV_TRANS_RF_MCHIP_DENIAL = 12;        /*RF M/CHIP transaction denial */
	public static final int EMV_TRANS_RF_MCHIP_GOONLINE = 13;        /*RF M/CHIP transaction go online */
	public static final int EMV_TRANS_RF_MAG_GOONLINE = 14;        /*RF Mag Stripe transaction go online  */
	public static final int EMV_TRANS_RF_MAG_ACCEPT = 15;        /*RF Mag Stripe transaction aproved (refund transaction)  */

	public static final int EMV_TRANS_RF_ACTIVE_CARD = 16;        /*RF active card*/
	public static final int EMV_TRANS_RF_TRYOTHERINT = 17;        /*RF try another interface*/
	public static final int EMV_TRANS_RF_ACTIVE_KERNEL = 18;        /**/
	public static final int EMV_TRANS_RF_SELECT_NEXT_AID = 19;        /*exit kernel and select next aid*/
	public static final int EMV_TRANS_RF_MAG_DENIAL = 20;

	/********** flow control flag********************/
	public static final int EMV_TRANS_GOTOTERMINATE = 0;
	public static final int EMV_TRANS_SENDMESSAGE = 30;
	

	public static final int KERNEL_ID_PAYPASS = 0x02;
	public static final int KERNEL_ID_PAYWAVE = 0x03;
	public static final int KERNEL_ID_EXPRESSPAY = 0x04;
	public static final int KERNEL_ID_JCB = 0x05;
	public static final int KERNEL_ID_DISCOVER = 0x06;
	public static final int KERNEL_ID_UNIONPAY = 0x07;
	public static final int KERNEL_ID_RUPAY = 0x0D;
	public static final int KERNEL_ID_MCCS = 0x20;
	public static final int KERNEL_ID_INTERAC = 0x21;
	public static final int KERNEL_ID_MADA = 0x2D;
	public static final int KERNEL_ID_MIR = 0x810643;
	public static final int KERNEL_ID_MULTIBANCO = 0xC14D42;
	
	
	public static final int TRANS_MODE = 0xDF1F;
//	public static class TransMode{
		
		/*EMV*/
//		public static final int TRANS_MODE_EMV = 1;
//		public static final int TRANS_MODE_ECASH = 2;
		/*Unionpay*/
		public static final int TRANS_MODE_UNIONPAY_QPBOC = 0x06;
		public static final int TRANS_MODE_UNIONPAY_PBOC = 0x07; 
		public static final int TRANS_MODE_UNIONPAY_MSD = 0x08;
		/*Paywave*/
		public static final int TRANS_MODE_PAYWAVE_QVSDC = 0x0B;
		public static final int TRANS_MODE_PAYWAVE_VSDC = 0x0C;
		public static final int TRANS_MODE_PAYWAVE_WAVE2 = 0x0D;
		public static final int TRANS_MODE_PAYWAVE_MSD = 0x0E;
		public static final int TRANS_MODE_PAYWAVE_MSD_LEGACY = 0x0F;
		/*paypass*/
		public static final int TRANS_MODE_PAYPASS_MCHIP = 0x10;
		public static final int TRANS_MODE_PAYPASS_MSTRIPE = 0x11;
		/*D-PAS*/
		public static final int TRANS_MODE_DPAS_EMV = 0x15;
		public static final int TRANS_MODE_DPAS_MSTRIPE = 0x16;
		public static final int TRANS_MODE_DPAS_ZIP = 0x17;
		/*AMEX*/
		public static final int TRANS_MODE_EXPRESSPAY_EMV = 0x1A;
		public static final int TRANS_MODE_EXPRESSPAY_MSTRIPE = 0x1B;
		public static final int TRANS_MODE_EXPRESSPAY_MOBLIE_EMV = 0x1C;
		public static final int TRANS_MODE_EXPRESSPAY_MOBLIE_MSTRIPE = 0x1D;
		/*JCB*/
		public static final int TRANS_MODE_JCB_EMV = 0x1F;
		public static final int TRANS_MODE_JCB_MSTRIPE = 0x20;
		public static final int TRANS_MODE_JCB_LEGACY = 0x21;
		/*pure (MCCS mada)*/
		public static final int TRANS_MODE_PURE_EMV = 0x24;
		public static final int TRANS_MODE_MCCS_EMV = TRANS_MODE_PURE_EMV;
		/*Interac*/
		public static final int TRANS_MODE_INTERAC_EMV = 0x29;
		/*Rupay*/
		public static final int TRANS_MODE_RUPAY_EMV = 0x2E;
		
//	}
		
	/**
	STENTRYPOINTOPT.ucCtrl
	implementation of PSE with selection of kernel based on DF61 if 9F2A is missing
	*/
	public static final int EMV_EP_CTRL_CK_DF61 = 0x01;
	public static final int EMV_EP_CTRL_CK_TERMINAL_PRIORITY = 0x02;
	public static final int EMV_EP_CTRL_CK_CANDIDATE_LIST  = 0x04;
	public static final int EMV_EP_CTRL_CK_CANDIDATE_LIST_ALL = 0x08;


	
}
