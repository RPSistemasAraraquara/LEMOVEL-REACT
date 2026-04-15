package com.newland.emv.jni.type;

public class capk{
	public byte[] 	pk_modulus = new byte[248];
	public byte 	pk_mod_len;
	public byte[]	 pk_exponent = new byte[3];
	public byte[] 	_hashvalue = new byte[20];
	public byte[] 	_expired_date = new byte[4];
	public byte[] 	 _rid = new byte[5];
	public byte 	_index;
	public byte 	_pk_algorithm;
	public byte 	_hash_algorithm;
	public byte 	_disable;
	public byte[] 	_resv = new byte[3];
}
