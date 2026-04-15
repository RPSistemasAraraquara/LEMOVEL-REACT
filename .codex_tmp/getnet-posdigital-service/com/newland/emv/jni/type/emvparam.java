package com.newland.emv.jni.type;

public class emvparam
{
	public byte[]		_tac_default = new byte[5];
	public byte[]		_tac_denial = new byte[5];
	public byte[]		_tac_online = new byte[5];
	public byte			_target_percent;                                                
	public byte			_max_target_percent;                                       
	public byte[]		_threshold_value = new byte[4];
	public byte[]		_trans_ref_conv = new byte[4];
	public byte			_script_dev_limit;                                          
	public byte[]		_ics = new byte[7];
	public byte			_status;                                                     
	public byte			_ec_indicator;                               
	public byte			_type;                                    
	public byte[]		_cap = new byte[3];
	public byte[]		_add_cap = new byte[5];
	public byte[]		_aid = new byte[16];
	public byte			_aid_len;                       
	public byte[]		_app_ver = new byte[2];
	public byte			_pos_entry;
	public byte[]		_floorlimit = new byte[4];
	public byte[]		_acq_id = new byte[6];
	public byte[]		_mer_category_code = new byte[2];
	public byte[]		_merchant_id = new byte[15];
	public byte[]		_trans_curr_code = new byte[2];
	public byte			_trans_curr_exp;                           
	public byte[]		_trans_ref_curr_code = new byte[2];
	public byte			_trans_ref_curr_exp;
	public byte[]		_term_country_code = new byte[2];
	public byte[]		_ifd_serial_num = new byte[8];
	public byte[]		_terminal_id = new byte[8];
	public byte			_default_ddol_len;
	public byte			_default_tdol_len;             
	public byte[]		_default_ddol = new byte[252];
	public byte[]		_default_tdol = new byte[252];
	public byte			_riskmana_data_len;
	public byte[]		_riskmana_data = new byte[8];
	public byte[]		_merchant_name = new byte[20];
	public byte			_app_sel_indicator;
	public byte			_fallback_posentry;
	public byte			_limit_exist;                                
	public byte[]		_ec_limit = new byte[6];
	public byte[]		_cl_limit = new byte[6];
	public byte[]		_cl_offline_limit = new byte[6];
	public byte[]		_cvm_limit = new byte[6];
	public byte[]		_trans_prop = new byte[4];
	public byte			_status_check;
	public byte			_appid;
	public byte[]		_resv_old = new byte[2];
	
	/************ The following is version 4.2C new parameter *************/
	//public byte[]		MerchantName = new byte[20];
	public byte			PPTlvLen;
	public byte[]		PPTlv = new byte[55];
	
	/************** The following is Paypass new parameter **************/
	public byte			DefaultUdolLen;
	public byte[]		DefaultUdol = new byte[252];
	public byte			MagStripeIndicator;
	public byte[]		MagAppVer = new byte[2];
	public byte			DataExchangeSupport;
	public byte			KernelConfig;
	public byte			MaxNumTornLog;
	public byte			BalanceReadFlag;
	
	/************** The following is Paywave new parameter **************/
	public byte[]		PwConfig = new byte[2];
	public byte			CvmReq;
	public byte			DdaVer;
	public byte[]		ResvPw = new byte[4];
	
	/*******Entry Point Configuration Data per Combination A-Table 5-2* ***/
	public byte[]		KernelId = new byte[8];
	public byte			VisaTtqPresent;
	public byte			StatusCheckSupport;
	public byte			ZeroAmountAllow;
	public byte			ExtendAidSupport;
	public byte			ClssCardholderVerifyAllow;
	
	/******** qVSDC support DRL application ID[4]**********/
	public byte			DrlStatus;
	public byte[]		DrlData = new byte[8*36];
	
	/******************** 以下�? Paypass 版本的结构体 ***********************/
	public byte			MagStripeCvm;
	public byte[]		MaxLifetimeTornLog = new byte[2];
	public byte			MobileSupportIndicator;
	public byte			MagStripeNoCvm;
	public byte			CapNoCvm;
	
	/******************** 以下�? ExpressPay 版本的结构体 ********************/
	public byte			EXTerminalCap;
	public byte			EXRandomScope;
	public byte			EXTimeExpire;
	
	public byte         TerminalPriority;
	public byte			TransType;//该条aid对应的交易类型，当TransTypeCheckFlag==1时生效�??
	
	public byte[]		CombinationOP = new byte[2];//JCB Combination Options DF60
	public byte[]		TIP = new byte[3];//JCB Terminal Interchange Profile 9F53
	
	public byte			TransTypeCheckFlag;//该条aid是否支持交易类型选择
	
	public byte[]		Resv = new byte[33];

}
