package com.newland.emv.jni.service;

import com.newland.emv.jni.type.aidpoint;
import com.newland.emv.jni.type.capk;
import com.newland.emv.jni.type.cardblk;
import com.newland.emv.jni.type.certblk;
import com.newland.emv.jni.type.emv_oper;
import com.newland.emv.jni.type.emv_opt;
import com.newland.emv.jni.type.emvparam;
import com.newland.emv.jni.type.ep_opt;
import com.newland.emv.jni.type.rf_transdata;

public class EmvJNIService {


	/*-----------------------------------Pad Method---------------------------------------------*/
	/**
	* @brief Start EMV IC card transaction
	* @param in  pstOpt  EMV Processing param struct
	*        emv_opt._seq_to to control where EMV kernel is running
	*        0-EMV_PROC_TO_APPSEL_INIT (Initiate Application)
	*		 1-EMV_PROC_TO_READAPPDATA (Read Application Data)
	*		 2-EMV_PROC_TO_OFFLINEAUTH (Data Authentication)
	*		 3-EMV_PROC_TO_RESTRITCT   (Processing Restrictions)
	*		 4-EMV_PROC_TO_CV          (Cardholder Verification)
	*		 5-EMV_PROC_TO_RISKMANA    (Terminal Risk Management)
	*		 6-EMV_PROC_TO_1GENAC      (Terminal Action Analysis and Card Action Analysis)
	*		 7-EMV_PROC_TO_2GENAC      (Script Processing and Completion)
	*		 8-EMV_PROC_CONTINUE       (execute EMV step until end)
	* @return
	* @li           Reference EmvConst
	* @li          <0    FAIL
	*/
	public native int jniemvStart(emv_opt popt);
	
	/**
	* @brief EMV IC card Transaction execution end function
	* @param in  nTransRes  transaction result
	* @return
	* @li           0    SUCC
	* @li          -1    FAIL
	*/
	public native int jniemvSuspend(int nTransRes);
	
	/**
	* @brief Start EMV RF card transaction
	* @param in    pstOpt      EMV Processing param struct
	*        in    nTransAmt   Transation Amount
	* @return
	* @li           Reference EmvConst
	* @li          <0    FAIL
	*/
	public native int jniemvrfstart(emv_opt pstEmvOption, long transAmount);
	
	/**
	* @brief EMV RF card Transaction execution end function
	* @param in    nTransRes  nTransRes  transaction result
	* @return
	* @li           0    SUCC
	* @li          -1    FAIL
	*/
	public native int jniemvrfsuspend(int nFinalFlag);

	/**
	* @brief get EMVLib Version。
	* @param 
	* @return
	* @li   EMVLib Version Number
	*/
	public native String jniemvgetVersion();

	/**
	* @brief get EMV error code
	* @param 
	* @return
	* @li   error code
	*/
	public native int jniemvErrorCode();
	
	/**
	* @brief Get a series of TLV specifies data in tagname[] (EMV Contact)
        		the data format of the returned data tag + len + value
	* @param in  punTagName     to save the data to obtain the label TLV array pointer to the first
	* @param in  nTagCnt        the number of data to obtain the TLV
	* @param out pusOutBuf      save the data pointer for the TLV
	* @param in  nMaxOutLen     obuf maximum array space constraints
	* @return -2   parameter is empty
	* 		  -1   Failure
	* 		  n    (n> 0) total length of the data obtained
	*/
	public native int jniemvFetchData(int[] punTagName, int nTagCnt, byte[] pusOutBuf, int nMaxOutLen);
	public native int jniemvFetchDataEx(int[] punTagName, int nTagCnt, byte[] pusOutBuf, int nMaxOutLen, int IsZeroLenTagAllow);
	
	/**
	* @brief get tagname value(EMV Contact)
	* @param in  unTagName    TAG name, i.e: 0x9F36
	* @param out pusData      character pointer, the head pointer storing data, which can not be NULL
	* @param in  nMaxOutLen   data stored in the maximum length
	* @return 0       label value does not exist
	* 		  >0     the length of the data obtained
	* 		  -1      Long data value exceeds the length limit data
	*/
	public native int jniemvgetdata(int unTagName, byte[] pusData, int nMaxOutLen);
	
	/**
	* @brief save tagname data values（EMV Contact）
	* @param in  unTagName    TAG name, i.e: 0x9F66
	* @param in  pusData      character pointer, the head pointer storing data, which can not be NULL
	* @param in  nMaxOutLen   data stored in the maximum length
	* @return 0       label value does not exist
	* 		  >0     the length of the data obtained
	* 		  -1      Long data value exceeds the length limit data
	*/
	public native int jniemvsetdata(int unTagName, byte[] pusData, int nMaxLen);

	/**
	* @brief set customer tag list
	* @param in  unCustomerTag    TAG name array
	* @param in  nTagCont   Tag Cont
	* @return 0       SUCC
	* 		  -1      FAIL
	*/
	public native int jniemvsetcustomertaglist(int[] unCustomerTag, int nTagCont);

	/**
	* @brief get custom tag data in the canditate
	* @param in  aid	  	AID
	* @param in  aidlen		length of AID	
	* @param out  customdata		output data with TLV format	
	* @return >=0 	  length of customdata
	*		  -1	  FAIL
	*/
	public native int jniemvgetcandidatecustomdata(byte[] aid, int aidlen, byte[] customdata);
	
//	/**
//	* @brief Update Terminal Configuration After Final Select(Application Selection)
//	* @param in TAG(DF11,DF12,DF13,
//	*			   DF15,DF16,DF17,
//	*			   DF22,DF23,DF24,DF25,9F7A)
//	* @param in  pusData    Value, can not be NULL
//	* @param in  nDataLen   Value length
//	* @return 0
//	*/
//	public native int jniemvsetconfig(int unTagName, byte[] pusData, int nDataLen);
	
	/**
	* @brief get EMV Transaction Detail
	* @param in    nRecNo      >0, Number of records to read
	*                          =PBOCLOG_SFI       transaction Detail SFI
	*                          =PBOCLOG_RECNUM    Number of records
	*                          =PBOCLOG_FMT       Transaction Detail Format
	*        out   pusOutBuf   Transaction Detail Data
	*        in    nMaxOutLen  Transaction Detail Data Maxlen
	*
	* @return
	* @li   < 0            FAIL
	*       > 0            Transaction Detail Data Len
	*       = 0            No Detail
	*/
	public native int jniemvGetPBOCLog(int nRec, byte[] pusOut, int nOutMaxLen);
	
	/**
	* @brief get EMV ECLoad Log
	* @param in    nRecNo      >0, Number of records to read
	*                          =PBOCLOG_SFI       ECLoad Log SFI
	*                          =PBOCLOG_RECNUM    Number of records
	*                          =PBOCLOG_FMT       ECLoad Log Format
	*        out   pusOutBuf   ECLoad Log Data
	*        in    nMaxOutLen  ECLoad Log Data Maxlen
	*
	* @return
	* @li   < 0            FAIL
	*       > 0            CLoad Log Data len
	*       = 0            No Log
	*/
	public native int jniemvGetecloadLog(int nRec, byte[] pusOut, int nOutMaxLen);
	
	/**
	* @brief Use GET DATA Command to get value of the Tag .
	* @param in  unTagName    tag which want to get;
	* @param out pusOut       the value of the tag;
	* @return 0   SUCC
	* 		  <0  FAIL 
	*/
	public native int jniemvICCGetDataByTagName(int unTagName, byte[] pusOut, int[] pnOutLen);
	
	/**
	* @brief initialize the EMV file path,
	* 			introduce EMV-related file names  and operation of function pointers,
	* 			Load AID lists and save g_emvconfig the default settings
	* @param in    * pfile      EMV file structure operation
	* @param in    * Poper      EMV related operations function pointer
	* @return      0            Success
	* 			  <0            Failure
	*/
	public native int jniemvInitialize(String pfile, emv_oper poper);
	/***
	 *   initialize the EMV file path, callback function
	 * @param pfile   EMV file structure operation
	 * @param poper   callback function
	 * @param flag   flag=1,same as jniemvInitialize
	 * 				 flag=0, callback function(emv_get_pinentry) compatibility with older versions
	 * @return
	 */
	public native int jniemvInitializeEx(String pfile, emv_oper poper, int flag);
	
	/**
	* @brief AID re-read the file, the establishment of AID List
	* @return 
	*/
	public native int jniemvbuildAidList();
	
	/**
	* @brief 操作密钥,包括更新,删除,使用,撤销. 注意该函数的所有操作顺序.
	* @param in out  pstCapk    传入或者传出的公钥结构体指针
	*        in      nMode      公钥操作方式
	*                           CAPK_RMV         公钥删除
	*                           CAPK_UPT         公钥更新
	*                           CAPK_DIS         公钥去激活
	*                           CAPK_ENB         公钥激活
	*                           CAPK_GET         公钥获取
	*                           CAPK_CLR         公钥清空
	* @return
	* @li    0     成功
	* @li   <0     失败
	*/
	public native int jniemvOperCAPK(capk pstCAPK, int nMode);
	
	/**
	* @brief 操作终端配置和AID: 获取,删除,更新等(注意:终端配置参数应写在文件中的第一个位置,
	*        AID从第2个参数位置开始写入)
	* @param in out pstAidParam   传入或者传出的AID结构体指针
	*        in     nMode         操作方式
	* @return
	* @li    0     成功
	* @li   <0     失败
	*/
	public native int jniemvOperAID(emvparam pstEmvParam, int nMode);
	
	/**
	* @brief 操作证书黑名单文件
	* @param in     *pstCertBlk  证书黑名单结构
	*        in     nMode        mode           操作的方式
	*                            STRUCT_DEL     删除一个结构
	*                            STRUCT_UPT     更新一个结构若不存在则新增
	*                            STRUCT_GET     获取一个结构
	*                            STRUCT_CLR     清空全部结构
	* @return
	* @li    0        成功
	* @li   <0        失败
	*/
	public native int jniemvopercertblk(certblk pstCertBlk, int nMode);
	
	/**
	* @brief 操作卡片黑名单文件
	* @param in     *pstCardBlk  卡片黑名单结构
	*        in     nMode        操作的方式
	*                            STRUCT_DEL     删除一个结构
	*                            STRUCT_UPT     更新一个结构若不存在则新增
	*                            STRUCT_GET     获取一个结构
	*                            STRUCT_CLR     清空全部结构
	* @return
	* @li    0        成功
	* @li   <0        失败
	*/
	public native int jniemvopercardblk(cardblk pstEmvCardBlack, int nMode);

	/**
	* @brief operation keys, including update, delete, use, remove
	* @param in  pstCAPK    incoming or outgoing public key pointers to structures
	* @param in  nMode      public key operation mode
	* @return 0   Success
	* 		  <0  failure 
	*/
	public native int jniSDKEPOperCAPK(capk pstCAPK, int nMode);
	
	/**
	* @brief operate the terminal configuration and AID: access, delete, update, etc.
    *            (Note: the terminal configuration parameters in the file should be written in the first place,
    *            AID from the second parameters of position to write)
	* @param in  pstEmvParam    incoming or outgoing AID structure pointer
	* @param in  nMode          operation mode
	* @return 0   Success
	* 		  <0  failure 
	*/
	public native int jniSDKEPOperAID(emvparam pstEmvParam, int nMode);
	public native int jniSDKEPOperAIDTlvData(aidpoint stAidPoint, int nMode, byte[] tlvData, int[] tlvDataLen);
	
	/**
	* @brief get contact AID Count
	* @return    AID Count
	*/
	public native int jniemvGetAIDCount();
	
	/**
	* @brief Get contact AID by Index number
	* @param in       nIndex  
	* @param out      pstEmvParam
	* @return
	* @li             0-SUCC
	*/
	public native int jniemvGetAID(int nIndex, emvparam pstEmvParam);

	/**
	* @brief get contactless AID Count
	* @return    AID Count
	*/
	public native int jniGetAIDCount();
	
	/**
	* @brief Get contactless AID by Index number
	* @param in       nIndex  
	* @param out      pstEmvParam
	* @return
	* @li             0-SUCC
	*/
	public native int jniGetAID(int nIndex, emvparam pstEmvParam);
	
	/**
	* @brief get CAPK Count
	* @return    CAPK Count
	*/
	public native int jniGetCAPKCount();
	
	/**
	* @brief Get CAPK by Index number
	* @param in       nIndex
	* @param out      pstCAPK
	* @return
	* @li             0-SUCC
	*/
	public native int jniGetCAPK(int nIndex, capk pstCAPK);
	
	/**
	* @brief set 9C transtype
	* @param in       value of 9C
	* @return
	* @li     0       SUCC
	*/
	public native void jniemvset9CTransType(byte value);
	
	/**
	* @brief Set whether to check blacklist
	* @param in       value  (1-Not check, 0-check)
	* @return
	* @li     0       SUCC
	*/
	public native void jniemvSetNotChkBlkCard(byte value);
	
	/**
	* @brief set NLTag
	* @param in       unTagName  NLtag name
	*        in       pusData    value
	*        in       nValueLen  datalen
	* @return
	* @li     0        SUCC
	* @li    <0        FAIL
	*/
	public native int jniemvWriteNLTagData(int unTagName, byte[] pusData, int nValueLen);

	/**
	* @brief callback set result
	* @param in    nUserSelect select retult
	* @param in    UserResult  set pin ,amount data
 	* @param in    nUserResultLen  pin ,amount data len
	* @return
	*/
	public native void jniemvSetUserResult(int nUserSelect, byte[] UserResult, int nUserResultLen);
	
	/**
	* @brief Set whether to use an external card reader 
	* 		(effect once time, the suspend flag is reset to 0)
	* @param in    0-not use, 1-use
	* @return
	*/
	public native void jniemvUseOutCardReaderOnce(int nIsUseOutCardReaderOnce);
		
	/**
	* @brief Set whether to use an external card reader 
	* @param in    0-not use, 1-use
	* @return
	*/
	public native void jniemvUseOutCardReader(int nIsUseOutCardReader);
	
	/**
	* @brief Set Extra Control Flag 
	* @param in    nExtraControlFlag:
	* @param in    0x01 = Do not beep when power down
	* @return
	*/
	public native void jniemvsetextracontrol(int nExtraControlFlag);
	
	/**
	* @brief 闪卡流程处理
	* @param in    pstEmvOption emvOption参数
	* @param in    InData       EMV Tag 数据
 	* @param in    nInDataLen   EMV Tag 数据长度
	* @return
	*/
	public native int jniemvFlashCard(emv_opt pstEmvOption, byte[] InData, int nInDataLen);
	
	/**
	* @brief 闪卡流程结束处理
	* @param in    pstEmvOption emvOption参数
	* @param in    InData       EMV Tag 数据
 	* @param in    nInDataLen   EMV Tag 数据长度
	* @return
	*/
	public native int jniemvFlashCardComplete(emv_opt pstEmvOption, byte[] InData, int nInDataLen);
	
	/**
	* @brief 将内存中所有的EMV tag数据打包成TLV形式
	* @param out   OutData      EMV Tag 数据
	* @return 
	* @li   (>=0)  EMV Tag Data数据长度
	* @li   (<0)   取到emvtag数据的长度失败
	*/
	public native int jniemvGetAllTagData(byte[] OutData);
	
	/**
	* @brief 设置emv运行到应用选择和应用初始化之间暂停，供上层在其间进行操作
	* @param in  nFlag =0 正常执行, =1 设置执行到最终应用选择并返回(仅当次交易生效)
	* @return
	*/
	public native void jniEMVrunToFinalSel(int nFlag);
	
	/**
	* @brief 获取是否是国际版（支持外卡版本）的EMV库
	* @return
	* @li      (1)-国际版
	* @li      (0)-国内版
	*/
	public native int jniIsINTLEMVVersion();
	
	
	
	/*-----------------------------------Rpc Method-----------------------------------------------*/
	/**
	* @brief 获取K21端的lunTagName[]里的一系列TLV数据,返回的数据格式为tag + len + value
	* @param in out   punTagName  保存要获取TLV数据的标签数组首指针
	*        in       nTagCnt     要获取的TLV数据个数
	*        out      pusOutBuf   保存获取的TLV数据指针
	*        in       nMaxOutLen  pusOutBuf数组的最大保存空间
	* @return
	* @li    -2        参数为空
	* @li    <0        失败
	* @li   n(n>0)     获取的数据总长度
	*/
	public native int jniemvrpcFetchData(int[] punTagName, int nTagCnt, byte[] pusOutBuf, int nMaxOutLen);
	
	/**
	* @brief 获取K21端EMV库中tagname的数据值
	* @param in       unTagName  要查找的标签名
	*        out      pusData    存放查找的数据值
	*        in       nMaxOutLen  pusOutBuf存放的最大长度限制
	* @return
	* @li    0         标签值不存在
	* @li    -1        数据值长超出nMaxOutLen长度限制
	* @li   n(n>0)     取到数据的长度
	*/
	public native int jniemvrpcgetdata(int unTagName, byte[] pusData, int nMaxOutLen);
	
	/**
	* @brief 设置K21端EMV库中unTagName的数据值
	* @param in       unTagName  要查找的标签名
	*        in       pusData    存放查找的数据值
	*        in       nMaxLen    pusData存放的长度
	* @return
	* @li     0        设置成功
	* @li    <0        设置失败
	* @li    -2        无设置该标签权限
	*/
	public native int jniemvrpcsetdata(int unTagName, byte[] pusData, int nMaxLen);
	
	/**
	* @brief 在K21端EMV库非接触交易执行函数。先调用此函数,进行非接触交易预处理。
	*        1:函数返回EMV_TRANS_RF_ACTIVECARD，则可以激活卡片.
	*           (1):卡片激活成功，则再次调用本函数继续交易
	*           (2):卡片激活失败，则结束交易
	*        2:函数返回<0,则交易中止
	*           (一定要调用EMV_rf_suspend()函数结束本次交易并处理相关数据)
	* @param in    pstOpt      需要传入的相关EMV交易选项
	*        in    nTransAmt   传入的固定交易金额(如果传入固定交易金额还要设定popt->nReqAmt = EMV_TRANS_REQAMT_NO)
	*                          不传入固定金额而是在函数内部由用户 输入金额的情况,则nTransAmt填写为0,并且设置
	*                          popt->nReqAmt = EMV_TRANS_REQAMT_RFPRECESS。
	* @return
	* @li          交易结果返回值
	*/
	public native int jniemvrpcrfstart(emv_opt pstEmvOption, long transAmount);
	
	/**
	* @brief K21端EMV库射频卡交易结束处理函数。
	* @param in    nTransRes  最终交易结果(交易接受,交易拒绝...)
	* @return
	* @li    0     总是成功
	*/
	public native int jniemvrpcrfsuspend(int nFinalFlag);
	
	/**
	* @brief K21端EMV库重新读取AID文件，建立AID List
	* @param void
	* @return
	* @li     0               成功
	* @li    -1               失败
	*/
	public native int jniemvrpcbuildAidList();

	/**
	* @brief 获取K21端EMV交易的错误码
	* @param in    无
	* @return
	* @li          错误码
	*/
	public native int jniemvrpcErrorCode();
	
	/**
	* @brief copy one of the kernel file to K21/MPOS,
		 While the kernel file changed, you should use this interface to synchronize
	* @param in  type of kernel file 
	*			0- kernel1.app,
	*			1-	ca.pk,
	*			2-	card.pblk,
	*			3- cert.cblk
	* @return
	* @li     0               success
	* @li    -1               failure
	*/
	public native int jniSyncRpcFiles(int type);
	
	/**
	* @brief synchronize all of the kernel file between Android with K21/MPOS, 
	*	copy or delete the kernel files(kernel1.app,ca.pk,card.pblk,cert.cblk)
	*	you should use this interface every time your “apk”  run.	
	* @return
	* @li     0               success
	* @li    -1               failure
	*/
	public native int jniSyncAllRpcFiles();
	
	
	/*--------------------------------Entrypoint Method-----------------------------------------*/
	
	/**
	* @brief initialize the EMV file path,
	* 			introduce EMV-related file names  and operation of function pointers,
	* 			Load AID lists and save g_emvconfig the default settings
	* @param in    * pfile      EMV file structure operation
	* @param in    * Poper      EMV related operations function pointer
	* @return      0            Success
	* 			  <0            Failure
	*/
	public native int jniSDKEntryPointInitialize(String pfile, emv_oper poper);
	public native int jniRpcSDKEntryPointInitialize(String pfile, emv_oper poper);
	public native int jniNLSDKEntryPointInitialize(String pfile, emv_oper poper);
	
	/**
	* @brief Kernel Processing
	* @param in    entry_point_opt 	* popt       Processing param struct;
	* @param in    TRF_transData 	*pdata 	 Transaction Data, eg. Amount that input, used for transaction process;
	* @return      
	*/
	public native int jniSDKEntryPointProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKPayPassProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKPayWaveProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKExpressPayProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKJCBProcess(ep_opt popt, rf_transdata rfdata);	
	public native int jniSDKDiscoverPayProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKQpbocProcess(ep_opt popt, rf_transdata rfdata);	
	public native int jniSDKPureProcess(ep_opt popt, rf_transdata rfdata);	
	public native int jniSDKInteracProcess(ep_opt popt, rf_transdata rfdata);	
	public native int jniSDKRupayProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKMIRProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniSDKMultibancoProcess(ep_opt popt, rf_transdata rfdata);
	
	public native int jniRpcSDKEntryPointProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKPayPassProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKPayWaveProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKExpressPayProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKJCBProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKDiscoverPayProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKQpbocProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKPureProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKInteracProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcSDKRupayProcess(ep_opt popt, rf_transdata rfdata);
	
	public native int jniRpcClssPreProcess(ep_opt popt, rf_transdata rfdata);
	public native int jniRpcClssGetResult(ep_opt popt, rf_transdata rfdata);

	/*****************************************************************************
	*@fn		jniNLSDKCLL2PerformTransaction
	*@brief		contactless transation processing
	*@param		[IN][OUT] ep_opt:	Entry_Point Trading Options
	*@param		[IN][OUT] rfdata:	Trans Data Options
	*@param		[IN] Ctrl:	some ctrl data, 
									byte 1 seekcard flag 
										NO SEEK CARD =0,
										SEEK CARD IN APP = 1,	
										SEEK CARD IN SERVER = 2,	
										ACTIVE CARD IN SERVER = 3,
									btye 2 qpboc getdata flag
										QPBOC NONEED GET DATA = 0,
										QPBOC NEED GET DATA = 1,	
									byte 3 process light Flag(see the below, it need set the all four lights status)
									byte 4 card read ok light Flag(see the below, it need set the all four lights status)
										bit 8-7 first light 
												LED_RFID_BLUE_ON = 0x40,
	    										LED_RFID_BLUE_OFF = 0x80,
	   						 					LED_RFID_BLUE_FLICK = 0xc0,		
											bit 6-5 thirdlight
												LED_RFID_GREEN_ON = 0x10,      		
	    										LED_RFID_GREEN_OFF = 0x20,       	
	    										LED_RFID_GREEN_FLICK = 0x30,
											bit 4-3second   light
												LED_RFID_YELLOW_ON = 0x04,      		
	    										LED_RFID_YELLOW_OFF = 0x08,       	
	    										LED_RFID_YELLOW_FLICK = 0x0c, 
											bit 2-1 four light
												LED_RFID_RED_ON = 0x01,
	    										LED_RFID_RED_OFF = 0x02,
	    										LED_RFID_RED_FLICK = 0x03,
									byte 5 AfterFinalSelect callback Flag
										NO NEED CALLBACK = 0,
										NEED CALLBACK = 1,	
	*@param		[IN] ProcessData:	the tlv trans data 
	*@param		[IN] ProcessDataLen:	tlv Date len
	*@return	transaction result
	*@note
	*****************************************************************************/
	public native int jniNLSDKCLL2PerformTransaction(ep_opt epopt, rf_transdata rfdata, byte[] Ctrl, byte[] ProcessData, int ProcessDataLen);
	
	/**
	* @brief the end of the EMV transaction execution function to execute trades flag variable emptying operation.
	* @param in    trans_final the final result of a transaction
	* @return 0 is successful   -1 Failed
	*/
	public native int jniSDKEntryPointSuspend(int nTransFinal);
	public native int jniSDKPayPassSuspend(int nTransFinal);
	public native int jniSDKPayWaveSuspend(int nTransFinal);
	public native int jniSDKExpressPaySuspend(int nTransFinal);
	public native int jniSDKJCBSuspend(int nTransFinal);
	public native int jniSDKDiscoverPaySuspend(int nTransFinal);
	public native int jniSDKQpbocSuspend(int nTransFinal);
	public native int jniSDKPureSuspend(int nTransFinal);
	public native int jniSDKInteracSuspend(int nTransFinal);
	public native int jniSDKRupaySuspend(int nTransFinal);
	public native int jniSDKMIRSuspend(int nTransFinal);
	public native int jniSDKMultibancoSuspend(int nTransFinal);
	
	public native int jniRpcSDKEntryPointSuspend(int nTransFinal);
	public native int jniRpcSDKPayPassSuspend(int nTransFinal);
	public native int jniRpcSDKPayWaveSuspend(int nTransFinal);
	public native int jniRpcSDKExpressPaySuspend(int nTransFinal);
	public native int jniRpcSDKJCBSuspend(int nTransFinal);
	public native int jniRpcSDKDiscoverPaySuspend(int nTransFinal);
	public native int jniRpcSDKQpbocSuspend(int nTransFinal);
	public native int jniRpcSDKPureSuspend(int nTransFinal);
	public native int jniRpcSDKInteracSuspend(int nTransFinal);
	public native int jniRpcSDKRupaySuspend(int nTransFinal);
	

	/**
	* @brief Get a series of TLV specifies data in tagname[]
        		the data format of the returned data tag + len + value
	* @param in  punTagName     to save the data to obtain the label TLV array pointer to the first
	* @param in  nTagCnt        the number of data to obtain the TLV
	* @param out pusOutBuf      save the data pointer for the TLV
	* @param in  nMaxOutLen     obuf maximum array space constraints
	* @return -2   parameter is empty
	* 		  -1   Failure
	* 		  n    (n> 0) total length of the data obtained
	*/
	public native int jniSDKEPFetchData(int[] punTagName, int nTagCnt, byte[] pusOutBuf, int nMaxOutLen);
	public native int jniSDKEPFetchDataEx(int[] punTagName, int nTagCnt, byte[] pusOutBuf, int nMaxOutLen, int IsZeroLenTagAllow);
	public native int jniRpcSDKEPFetchData(int[] punTagName, int nTagCnt, byte[] pusOutBuf, int nMaxOutLen);
	
	/**
	* @brief request tagname value
	* @param in  unTagName    TAG name, i.e: 0x9F36
	* @param out pusData      character pointer, the head pointer storing data, which can not be NULL
	* @param in  nMaxOutLen   data stored in the maximum length
	* @return 0       label value does not exist
	* 		  >0     the length of the data obtained
	* 		  -1      Long data value exceeds the length limit data
	*/
	public native int jniSDKEPGetData(int unTagName, byte[] pusData, int nMaxOutLen);
	public native int jniRpcSDKEPGetData(int unTagName, byte[] pusData, int nMaxOutLen);
	
	/**
	* @brief save tagname data values
	* @param in  unTagName    TAG name, i.e: 0x9F36
	* @param in  pusData      character pointer, the head pointer storing data, which can not be NULL
	* @param in  nMaxOutLen   data stored in the maximum length
	* @return 0       label value does not exist
	* 		  >0     the length of the data obtained
	* 		  -1      Long data value exceeds the length limit data
	*/
	public native int jniSDKEPSetData(int unTagName, byte[] pusData, int nMaxLen);
	public native int jniRpcSDKEPSetData(int unTagName, byte[] pusData, int nMaxLen);

	/**
	* @brief set customer tag list
	* @param in  unCustomerTag    TAG name array
	* @param in  nTagCont   Tag Cont
	* @return 0       SUCC
	* 		  -1      FAIL
	*/
	public native int jniSDKEPSetCustomerTagList(int[] unCustomerTag, int nTagCont);

	/**
	* @brief get custom tag data in the canditate
	* @param in  aid	  	AID
	* @param in  aidlen		length of AID	
	* @param out  customdata		output data with TLV format	
	* @return >=0 	  length of customdata
	*		  -1	  FAIL
	*/
	public native int jniSDKEPGetCandidateCustomData(byte[] aid, int aidlen, byte[] customdata);
	
//	/**
//	* @brief Update Terminal Configuration After Final Select(Application Selection)
//	* @param in TAG(DF11,DF12,DF13,
//	*			DF15,DF16,DF17,
//	*			DF22,DF23,DF24,DF25,9F7A
//				DF2E,DF2F,DF32,DF33,DF3D,DF63,DF64)
//	* @param in  pusData    Value, can not be NULL
//	* @param in  nDataLen   Value length
//	* @return 0
//	*/
//	public native int jniSDKEPSetConfig(int unTagName, byte[] pusData, int nDataLen);
	
	/**
	* @brief error code
	* @return error code
	*/
	public native int jniSDKEPErrorCode();
	public native int jniRpcSDKEPErrorCode();

	/**
	* @brief AID re-read the file, the establishment of AID List
	* @return 
	*/
	public native int jniSDKEntryPointBuildAIDList();
	public native int jniRpcSDKEntryPointBuildAIDList();
	
	/**
	* @brief version buffer
	* @return version buffer
	*/
	public native String jniSDKEPGetVersion();
	public native String jniSDKPPGetVersion();
	public native String jniSDKPWGetVersion();
	public native String jniSDKXPGetVersion();
	public native String jniSDKJCBGetVersion();
	public native String jniSDKDPGetVersion();
	public native String jniSDKQpbocGetVersion();
	public native String jniSDKPEGetVersion();
	public native String jniSDKIEGetVersion();
	public native String jniSDKRUGetVersion();
	public native String jniSDKMIRGetVersion();
	public native String jniSDKMBGetVersion();
	
	
	public native String jniRpcSDKEPGetVersion();
	public native String jniRpcSDKPPGetVersion();
	public native String jniRpcSDKPWGetVersion();
	public native String jniRpcSDKXPGetVersion();
	public native String jniRpcSDKJCBGetVersion();
	public native String jniRpcSDKDPGetVersion();
	public native String jniRpcSDKQpbocGetVersion();
	public native String jniRpcSDKPEGetVersion();
	public native String jniRpcSDKIEGetVersion();
	public native String jniRpcSDKRUGetVersion();
	
	/*    return CLL2 Status buffer[40]*/
	public native String jniSDKEPGetCLL2Status();	
	public native String jniRpcSDKEPGetCLL2Status();

	


	/**
	* @brief Use GET DATA Command to get value of the Tag .
	* @param in  unTagName    tag which want to get;
	* @param out pusOut       the value of the tag;
	* @return 0   Success
	* 		  <0  failure 
	*/
	public native int jniSDKEPICCGetDataByTagName(int unTagName, byte[] pusOut, int[] pnOutLen);
	public native int jniRpcSDKEPICCGetDataByTagName(int unTagName, byte[] pusOut, int[] pnOutLen);
	
	
	/**
	* @brief 设置非接运行到最终应用选择之后,应用初始化之前，供上层在其间进行操作
	* @param in  nFlag =0 正常执行, =1 设置执行到最终应用选择并返回(仅当次交易生效)
	* @return
	*/
	public native void jniSDKEPRunToFinalSel(int nFlag);
	public native void jniRpcSDKEPRunToFinalSel(int nFlag);
	
	/*--------------------------------Debug Method-----------------------------------------*/
	/**
	* @brief Set Debug Mode
	*	 When you use this interface to start DEBUG (1-open),
	*	 while you do the transaction of Contact/Contactless,
	*	 the contact kernel will display the DEBUG-LOG on [logcat] immediately,
	*	 the contactless kernel will record the DEBUG-LOG and after you
	*	 finish the contactless transaction, you may Export the log to [logcat].
	* @param in   lv 0x00-close,
	* 			  lv 0x01-log with normal debug informaiton, normal/recommand use this value;
	* 			  lv 0x03-log with all of the debug information
	* @return
	*/
	public native void jniemvSetDebugMode(int debugLv);
	
	/**
	* @brief Export Debug-log to [logcat] (used for contactless kernel) 
	* @return SUCC
	*/
	public native int jniRpcExportEmvDebugLog();
	
	/**
	* @brief Delete emv transaction log(emv.log)
	* @return SUCC
	*/
	public native int jniDeleteEmvTransLog();


	static 
	{		
		try {
			System.loadLibrary("emvjni");
		} catch (Exception e) {
			
		}
		
	}

}
