package com.newland.emv.jni.type;

public class aidpoint{
	public byte[] 	usAid = new byte[16];
	public byte	 	ucAidLen;                                                  
	public byte[] 	usKernelID = new byte[8];
	public byte		ucTransTypeCheckFlag;                                                                 
	public byte 	ucTransType;                                                            
    public byte[] 	usRsv = new byte[50];
}
