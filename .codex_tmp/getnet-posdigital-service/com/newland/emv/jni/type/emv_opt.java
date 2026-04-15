package com.newland.emv.jni.type;

public class emv_opt
{
    public byte		_trans_type;					/**< in, transaction type, see above */                                      
    public int		_seq_to;						/**< in, when to terminate the session */                         
    public int		_request_amt;         
    public int		_force_online_enable;			/**< in, whether the force online option opened */                
    public int		_account_type_enable;			/**< in, whether the account type selection opened */             
    public byte[]	_online_pin = new byte[12];		/**< out, string with '\0' if online pin is entered */            
    public byte[]	_iss_script_res = new byte[100];/**< out, if issuer script result exists */                       
    public int		_iss_sres_len;          
    public int		_advice_req;					/**< out, if advice is required (must be supported by ics) */     
    public int		_force_accept_supported;		/**< out, if ICS support it */                                    
    public int		_signature_req;					/**< out, if the CVM finally request a signature */ 
    public byte[]	_auth_resp_code = new byte[2];	/**< in, 8A from the host */                             
    public byte[]	_field55 = new byte[256];		/**< in, field55 or tlv decoded data from the host */    
    public int		_field55_len;                                                                      
    public int		_online_result;					/**< in, the online result */                            
    public int		_trans_ret;						/**< transaction return */
}

