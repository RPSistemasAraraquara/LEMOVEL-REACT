package com.newland.emv.jni.listener;

import com.newland.emv.jni.type.candidate;
import com.newland.emv.jni.type.ep_opt;
import com.newland.emv.jni.type.publickey;
import com.newland.emv.jni.type.ui_request_data;

public interface EmvJNIListener 
{
	/**
	* @brief Enter online PIN/offline PIN
	* @param type in PIN type,used for display guide message
					  0x01   offline PIN 
					  0x02   last/finally offline PIN
					  0x03    online PIN
			 pinPK  in  PIN public key,used for enciphered offline PIN,
			 			if (pinPK.pk_mod_len > 0) then process enciphered offline PIN
			 pinentry  out Out PINBLOCK, used for online PIN
			 
	* @return
			  -1   FAIL
		      -2   PIN  BYPASS
		      -3   Timeout
		      >0   case ONLINE PIN, mean the length of the PINBLOCK
		      	   case OFFLINE PIN, mean the SW of authentication APDU,e.g.0x9000,0x6a82
	* @author Linld
	* @date 2018-1-11
	*/
    public int emv_get_pinentry(int type, publickey pinPK,  byte[] pinentry);
    
    /**
	* @brief Select the results of the voice reference of the issuer
	* @param in pan        
	* @param in panlen     
	* @return
	* 0-Accept ; 1-Refuse ; -1-FAIL
	*/
    public int iss_ref(byte[] pan, int panlen);
    
    /**
	* @brief Account type selection
	* @param 
	* @return >0-Selected account index; <0-FAIL
	*/
    public int acctype_sel();
    
    /**
	* @brief Terminal Sequence counter
	* @return (Terminal Sequence counter)++
	*/
    public int inc_tsc();
    
    /**
	* @brief Cardholder certificate
	* @param in type        Certificates type(ID, Military officer, Passport, Entry permit, Temporary ID, Other)
	* @param in certNo      Identification Number
	* @param in len         Identification Number Length
	* @return 
	* 1-Identification success; 0-Identification failed
	*/
    public int cert_confirm(byte type, byte[] pcon, int len);
    
    /**
	* @brief Screen display information
	* @param in title      
	* @param in msg        information
	* @param in len        information length
	* @param in yesno      Need to display (confirm and cancel)
	* @param in waittime   waittime
	* @return 
	* if yesno=1,  1-confirm; 0-cancel;
	* if yesno=0,  Return value is meaningless
	*/
    public int lcd_msg(char[] title, byte[] msg, int len,  int yesno, int waittime);
    
    /**
	* @brief Multiple application selection
	* @param in pcan Multi application list
	* @param in amt  Multi application count
	* @param in times  select time(control title display)
	* @return 
	*/
    public int candidate_sel(candidate[] pcan, int amt, int times);
    
    /**
	* @brief apdu interactive between ICcard and terminal
	* @param in cardno     
	* @param in inbuf      
	* @param in inlen      
	* @param out outbuf    
	* @param out olen      
	* @return >=0-SUCC,outbuf length; -1-FAIL
	*/
    public int emv_icc_rw(int cardno, byte[] inbuf, int inlen, byte[] outbuf, int olen);
    
    /**
	* @brief IC card power down
	* @param in cardno
	* @return 0-SUCC; 1-FAIL
	*/
    public int emv_rf_powerdown(int cardno);
    
    /**
	* @brief EC/emv select
	* @return 
	*  1-EC;
	*  0-EMV;
	* -1-Quit;
	* -3-Timeout;
	*/
    public int emv_ec_switch();
    
    /**
	* @brief IC card power up
	* @param in cardno  
	* @return 0-SUCC; 1-FAIL
	*/
    public int emv_icc_powerup(int[] cardno);
    
    /**
	* @brief input amount
	* @param in transtype        Trans Type
	* @param out pusBCDCash      Trans Amount
	* @param out pusBCDCashBack  Cashback Amount
	* @return 0-SUCC; 1-FAIL
	*/
    public int emv_get_bcdamt(byte ucTransType, byte[] pusBCDCash, byte[] pusBCDCashBack);
    
    
    /**
     * @brief Not used
     * @param msg
     * @return 0
     */
    public int outcome_msg(ui_request_data msg); 
    /**
     * @brief Not used
     * @param epopt
     * @return
     */
    public int send_msg(ep_opt epopt);
    
    /**
     * @brief used for Paypass DataExchange,DEK,DET
     * @param mestype=0x01, DEK
     *        mestype=0x02, DET
     * @return
     */
    public int dek_det(byte mestype, byte[] outbuf, int[] outbuflen);
    
    /**
     * @brief Sentout EMV DEBUG LOG
     * @param debuglog 
     * @param len
     * @return
     */
    public int emv_debug(byte[]debuglog, int len);

	/**
     * @brief Sentout LCD MESSAGE
     * @param msgID 
     * @param yesno
	 * @param waittime
     * @return
     */
	public int lcd_msg_new(int msgID, int yesno, int waittime);

	/**
     * @brief used for Multi Language Select
     * @param msg
     * @param len
	 * @param yesno
	 * @param waittime
     * @return
     */
	public int language_select(byte[] msg, int len, int yesno, int waittime);

	/**
     * @brief used for after final select
     * @param aid
     * @param aidLen
	 * @param usTlvData
	 * @param nTlvDataLen
     * @return
     */
	public int after_final_select(byte[] aid, int aidLen, byte[] usTlvData, int[] nTlvDataLen);
    
}
