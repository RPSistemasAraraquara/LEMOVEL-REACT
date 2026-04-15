package com.newland.emv.jni.type;

public class EmvConfig {


	public static final int _EMVPARAM_DF11_TACDEFAULT =	0xDF11;	/*default Terminal Action Code, n5*/
	public static final int _EMVPARAM_DF13_TACDENIAL =	0xDF13;	/*denial Terminal Action Code, n5*/
	public static final int _EMVPARAM_DF12_TACONLINE =	0xDF12;	/*online Terminal Action Code, n5*/
	public static final int _EMVPARAM_DF17_TARGETPER =	0xDF17;	/*target percent, n1*/
	public static final int _EMVPARAM_DF16_MAXTARPER =	0xDF16;	/*max target percent,n1*/
	public static final int _EMVPARAM_DF15_THRESHOLDVA =	0xDF15;	/*thresold value, n4*/
	public static final int _EMVPARAM_DF22_TRANSCONV =	0xDF22;	/*transaction reference currency convert, n4,default 0 */
	public static final int _EMVPARAM_DF23_SCRDEV =	0xDF23;	/*script length limit ,n1, default 0*/
	public static final int _EMVPARAM_DF24_ICS =	0xDF24; 	/* ICS (Implementation Comformance Statement), b, 7*/
	public static final int _EMVPARAM_DF25_STATUS =	0xDF25;	/* Test type indicator,n1*/
	public static final int _EMVPARAM_9F7A_ECIND = 0x9F7A;	/* 9F7A if Terminal  support EC?Or paywave: supprt wave2 ?support  = 1, n1*/
	public static final int _EMVPARAM_9F35_TYPE = 0x9F35;	/* 9F35(Terminal), n2, 1 */
	public static final int _EMVPARAM_9F33_CAP = 0x9F33;	/* 9F33(Terminal), b,  3 */
	public static final int _EMVPARAM_9F40_ADDCAP =	0x9F40;	/* 9F40(Terminal), b,  5 */
	public static final int _EMVPARAM_9F06_AID = 0x9F06;	/* 4F(ICC), 9F06(Terminal), b, 5-16 bytes */
	public static final int _EMVPARAM_9F09_APPVER =	0x9F09;	/* 9F09(Terminal), b, 2 bytes */
	public static final int _EMVPARAM_9F39_POSENTRY = 0x9F39;	/* 9F39(Terminal), n2, 1 bytes */
	public static final int _EMVPARAM_9F1B_FLOORLIMIT =	0x9F1B;	/* 9F1B(Terminal), b, 4 bytes */
	public static final int _EMVPARAM_9F01_ACQID =	0x9F01;	/* 9F01(Terminal), n6-11, 6 bytes */
	public static final int _EMVPARAM_9F15_MERCACODE =	0x9F15;	/* 9F15(Terminal), n4, 2 bytes */
	public static final int _EMVPARAM_9F16_MERCHID = 0x9F16;	/* 9F16(Terminal), ans15, 15 bytes */
	public static final int _EMVPARAM_5F2A_TRANSCCODE =	0x5F2A;	/* 5F2A(Terminal), n3, 2 bytes */
	public static final int _EMVPARAM_5F36_TRANSCEXP =	0x5F36;	/* 5F36(Terminal), n1, 1 bytes */
	public static final int _EMVPARAM_9F3C_TRANSREFCCODE =	0x9F3C;	/* 9F3C(Terminal), n3, 2 bytes */
	public static final int _EMVPARAM_9F3D_TRANSREFCEXP =	0x9F3D;	/* 9F3D(Terminal), n1, 1 bytes */
	public static final int _EMVPARAM_9F1A_TERMCCODE =	0x9F1A;	/* 9F1A(Terminal), n3, 2 bytes */
	public static final int _EMVPARAM_9F1E_IFDSERNUM =	0x9F1E;	/* 9F1E(Terminal), an8, 8 bytes */
	public static final int _EMVPARAM_9F1C_TERMID =	0x9F1C;	/* 9F1C(Terminal), an8, 8 bytes */
	public static final int _EMVPARAM_DF44_DEDDOL =	0xDF44;	/*default ddol, var*/
	public static final int _EMVPARAM_DF45_DETDOL =	0xDF45;	/* default tdol, var*/
	public static final int _EMVPARAM_DF01_APPSELIND =	0xDF01;	/*application select indicator,n1*/
	public static final int _EMVPARAM_DF26_FALLPOTERY =	0xDF26;	/* fallback pos entry, n1*/
	public static final int _EMVPARAM_DF27_LIMITEXIST =	0xDF27;	/* limist exist?(To determine the identity of the following limit exists),b8, 1*/
	public static final int _EMVPARAM_9F7B_ECLIMIT = 0x9F7B;	/* 9F7B Electronic cash terminal limit n12  6bytes*/
	public static final int _EMVPARAM_DF20_CLLIMMIT =	0xDF20;	/* contactless terminal transaction limit n12  6bytes */		
	public static final int _EMVPARAM_DF19_CLOFFLIMIT =	0xDF19;	/* contactless terminal offline minimum limit n12  6bytes */	
	public static final int _EMVPARAM_DF21_CVMLIMT = 0xDF21;	/* terminal implement CVM Limit, n12  6bytes */	
	public static final int _EMVPARAM_9F66_TRANSPROP =	0x9F66;	 /* 9F66 Terminal transaction attribute ,b32  4bytes*/	
	public static final int _EMVPARAM_DF29_STATUSCHECK = 0xDF29;	/*The default of contactless status check is 0*/	
	public static final int _EMVPARAM_DF2A_APPID =	0xDF2A;	/* Application ID */	
	public static final int _EMVPARAM_9F4E_MERCNAME = 0x9F4E;	/* 9F4E(Terminal), ans20, 20 bytes */	
	public static final int _EMVPARAM_DF2B_DEUDOL =	0xDF2B;   /*default ddol (paypass+)*/    
	public static final int _EMVPARAM_DF2C_MAGSTRIND =	0xDF2C;	/*(paypass+) support mag stripe ?  1 support ;  0 not support [paypass]*/	
	public static final int _EMVPARAM_DF2D_MAGAPPVER =	0xDF2D;	 /*paypass mag stripe application version 9F6D*/	
	public static final int _EMVPARAM_DF2E_DEXCHANGE =	0xDF2E;	 /*support data exchang or not*/	
	public static final int _EMVPARAM_DF2F_KERNELCONF =	0xDF2F;	 /* b8  Only EMV mode b7  Only mag-stripe mode b6 On device cardholder verification*/	
	public static final int _EMVPARAM_DF32_MNUMTORN = 0xDF32;	/* Max Number of Torn Transaction Log Records !=0 support Torn*/	
	public static final int _EMVPARAM_DF33_BALANFLAG =	0xDF33;	/*00,NO; bit1:Balance Read Before GAC; bit2:Balance Read After GAC,*/	
	public static final int _EMVPARAM_DF34_PWCONFIG = 0xDF34;	/* paywave config */	
	public static final int _EMVPARAM_DF35_CVMREQ =	0xDF35;	/* paywave2 terminal require reader execute CVM */	
	public static final int _EMVPARAM_DF36_DDAVER =	0xDF36;	 /*0x00    support all dda version 0x01    support only version 0x01 */	
	public static final int _EMVPARAM_DF37_KERNELID = 0xDF37;	/*kernel id*/	
	public static final int _EMVPARAM_DF38_VISATTQ = 0xDF38;	/*unused 这个参数已经没用*/	
	public static final int _EMVPARAM_DF39_STATUSCHECK = 0xDF39;	/*status check*/	
	public static final int _EMVPARAM_DF3A_ZEROALLOW = 0xDF3A;	/*zero amount allow*/	
	public static final int _EMVPARAM_DF3B_EXAIDSUPP =	0xDF3B;	/*预留，默认都支持AID扩展�?	*/
	public static final int _EMVPARAM_DF3C_CLSSCVA =	0xDF3C;	/*是否允许持卡人确认的非接应用AID*/
	public static final int _EMVPARAM_DF3D_DRLSTATUS =	0xDF3D;	/*0x00 Deactivated; 0x01 Activated*/
	public static final int _EMVPARAM_DF3F_DRLDATA =	0xDF3F;	/*DRL Data len = 8*36 暂定�?8个DRL 数据，以兼容旧的配置文件*/
//由于paywave drl还是延用结构体，�?以以下tag无用�?
//	public static final int _EMVPARAM_9F5A_DRLAPPID	 =	0x9F5A;    /*9F5A application ID 1-4 */
//	public static final int _EMVPARAM_DF4C_CLLIMITEX =	0xDF4C;   /* limist exist? */
//	public static final int _EMVPARAM_DF4D_CLTRANLMT =	0xDF4D;   /* clss transaction limit n12  6bytes */
//	public static final int _EMVPARAM_DF4E_CLOFFLMT	 =	0xDF4E;    /* contactless offline limit n12  6bytes */
//	public static final int _EMVPARAM_DF4F_CLCVMLMT =	0xDF4F;   /* cvm limit   n12  6bytes */
	public static final int _EMVPARAM_DF42_MAGSCVM =	0xDF42;	/*Mag-stripe CVM Capability �? CVM Required */
	public static final int _EMVPARAM_DF43_MEXLTTORN =	0xDF43;	/*Max Lifetime of Torn Transaction Log Record  0x012c */
	public static final int _EMVPARAM_DF46_MOSUPPIND =	0xDF46;	/*Mobile Support Indicator*/	
	public static final int _EMVPARAM_DF47_MAGSNOCVM =	0xDF47;	/*Mag-stripe CVM Capability �? No CVM Required */	
	public static final int _EMVPARAM_DF48_CAPNOCVM =	0xDF48;	/*CVM Capability �? no CVM Required */	
	public static final int _EMVPARAM_DF49_EXTERMCAP =	0xDF49;	/*expresspay 3.0 终端性能9F6D*/	
	public static final int _EMVPARAM_DF4A_EXRANDOM =	0xDF4A;	/*expresspay 3.0 随机数范�?*/	
	public static final int _EMVPARAM_DF4B_EXTIMEEX =	0xDF4B;	/*expresspay 3.0超时时间*/	
	public static final int _EMVPARAM_DF52_PPTLV =	0xDF52;    /*只用于paypass3.0测试 设置 TAG值长度为0，或有任何的预设定�??*/
	public static final int _EMVPARAM_DF53_EXDRLDATA =	0xDF53;	 /*expresspay 3.1 drl limit*/
//paypass 3.1rrp协议新增llf20160613
	public static final int _EMVPARAM_DF54_MAXRRPGP =	0xDF54;	 /*paypass 3.1 rrp Maximum Relay Resistance Grace Period*/
	public static final int _EMVPARAM_DF55_MINRRPGP =	0xDF55;	 /*paypass 3.1 rrp Minimum Relay Resistance Grace Period*/
	public static final int _EMVPARAM_DF56_RRPAT =	0xDF56;	 /*paypass 3.1 rrp Relay Resistance Accuracy Threshold*/
	public static final int _EMVPARAM_DF57_RRPTTMT = 0xDF57;	 /*paypass 3.1 rrp Relay Resistance Transmission Time Mismatch Threshold*/
	public static final int _EMVPARAM_DF58_TETTFRRC	 =	0xDF58;	 /*paypass 3.1 rrp Terminal Expected Transmission Time For Relay Resistance C-APDU*/
	public static final int _EMVPARAM_DF59_TETTFRRR	 =	0xDF59;	 /*paypass 3.1 rrp Terminal Expected Transmission Time For Relay Resistance R-APDU*/

	public static final int _EMVPARAM_DF60_COMBINATIONOPT =	0xDF60;	//自定义，Combination options
	public static final int _EMVPARAM_9F53_TIP =	0x9F53;	//自定义，JCB Terminal Interchange Profile (static)
	public static final int _EMVPARAM_DF61_MDOL =	0xDF61;	//自定义，Default MDOL
	public static final int _EMVPARAM_DF62_CONTAPPCAP =	0xDF62;	//自定义，pure Contactless App Cap
	public static final int _EMVPARAM_DF63_IOOPTION =	0xDF63;	//自定义，pure io_options
	public static final int _EMVPARAM_DF64_TERMINALAIDVALUE =	0xDF64;   //pure terminal aid value
	public static final int _EMVPARAM_BF71_MEMSLOTREADTEM =	0xBF71;	//pure memory slot read tempklate
	public static final int _EMVPARAM_BF70_MEMSLOTUPDATETEM =	0xBF70;	//pure memory slot update tempklate
	public static final int _EMVPARAM_DF65_TERMINALPRIORITY =	0xDF65;   //spire �?求终端优先级
	public static final int _EMVPARAM_9F1D_TRMDATA = 0x9F1D;   //terminal risk manage data
	public static final int _EMVPARAM_9F76_TERMTRANSDATA =	0x9F76;	//pure terminal transactioin data
	public static final int _EMVPARAM_DF66_MTOL =	0xDF66;	//pure mtol
	public static final int _EMVPARAM_DF79_ATDTOL =	0xDF79;	//pure atdtol
	public static final int _EMVPARAM_DF7A_POSTIMEOUTTRANS = 0xDF7A;	//pure postimeout transaction
	public static final int _EMVPARAM_DF7B_AUTORUN =	0xDF7B;	//pure auto run
	public static final int _EMVPARAM_DF7C_POSTIMEOUTLONG =	0xDF7C;	//pure POSTIMEOUTLONG	
	public static final int _EMVPARAM_DF7D_TRANSTYPE =	0xDF7D;	//pure TYPEAAT
	public static final int _EMVPARAM_DF7E_ATOL =	0xDF7E;	//pure ATOL
	public static final int _EMVPARAM_9F59_TTI = 0x9F59;	//interac Terminal Transaction Information (TTI)
	public static final int _EMVPARAM_9F5E_TOS = 0x9F5E;	//interac Terminal Option Status (TOS)
	public static final int _EMVPARAM_9F58_MTI = 0x9F58;	//interac Merchant Type Indicator
	public static final int _EMVPARAM_9F5D_TerConRecLimit =	0x9F5D;	//interac Terminal Contactless Receipt Required Limit
	public static final int _EMVPARAM_9F5A_TTT = 0x9F5A;//interac TTT
	public static final int _EMVPARAM_DF4C_INTERAC_RELimit = 0xDF4C;	//interac INTERAC Retry Limit
	public static final int _EMVPARAM_DF7F_EMVCONFIGRES = 0xDF7F;	 /*use for feature*/
	public static final int _EMVPARAM_1F8101_TRANSTYPECKFLAG = 0x1F8101; //trans type check flag,use for paypass,n1 
	public static final int _EMVPARAM_1F8102_PPSEAIDSEL = 0x1F8102; //ContaceLess Select by AID list,n1
	
}
