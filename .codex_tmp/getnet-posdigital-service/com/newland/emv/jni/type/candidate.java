package com.newland.emv.jni.type;

public class candidate{
	public byte[] 	_aid = new byte[16];
	public byte	 	_aid_len;                  /**< length of AID */                                                        
	public byte[] 	_lable = new byte[20];
	public byte		_lable_len;                /**< length of lable*/                                                       
	public byte[] 	_preferred_name = new byte[20];
	public byte 	_preferred_name_len;       /**< length of preferred name */                                             
	public byte 	_priority;
	public byte  	_enable;
    public byte 	_flag;
    
    public byte     _limit_flag;
    public byte[] 	_kernel_id = new byte[8];
    public byte[] 	_extend_aid = new byte[16];
    public byte 	_extend_aid_len;
    public byte 	_status_type;
    public byte 	_terminal_aid_num;
    public byte     _terminal_priority;
    public byte     _9f2a_exist;
    public byte     _kernel_config;
    public byte[] 	_9f0a = new byte[255];
    public byte     _9f0a_len;

    public byte     _9f11_iss_code_idx;
    public byte     _exchange_flag;
    
    public int		_file_offset;              /**< the offset of this AID in the parameters file */                         
    public byte[] 	_resv = new byte[7];
}
