package com.newland.emv.jni.type;

public class ui_request_data {

	public byte		message_id;
	public byte		status;
	public byte[]	hold_time = new byte[3];
	public byte[]	language_preference = new byte[8];
	public byte		value_qualifier;
	public byte[]	value = new byte[6];
	public byte[]	currency_code = new byte[2];
	public byte[]	resv = new byte[6];
	
}
