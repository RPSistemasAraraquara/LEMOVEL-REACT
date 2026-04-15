package com.newland.emv.jni.type;

import com.newland.emv.jni.type.candidate;
import com.newland.emv.jni.type.ep_opt;
import com.newland.emv.jni.type.ui_request_data;


public interface emv_oper{
	
	/**
	* @brief 输入联机PIN/脱机PIN
	* @param type in 密码类型,用于显示密码提示??
					  0x01   脱机密码 
					  0x02   最后一次脱机密??
					  0x03   联机密码
			 pinPK  in  脱机密文PIN使用,表示PIN????, 其他情况(联机PIN、脱机明文PIN)为NULL,
			 			即当pk_mod_len > 0??, 使用脱机加密PIN
			 pinentry  out 联机PIN使用,返回联机PIN, 脱机PIN时没有使??,不进行赋??
			 
	* @return
			  -1    输入失败    故障
		      -2    ??输入      BYPASS
		      -3  Timeout
		      >0    联机PIN??,表示联机PIN的长??
		     	    脱机PIN??,表示卡片校验脱机PIN所返回的APDU响应码e.g.0x9000,0x6a82
	* @author Linld
	* @date 2018-1-11
	*/
    public int emv_get_pinentry(int type, publickey pinPK,  byte[] pinentry);
//    public int emv_get_pinentry(int type, byte[] pinentry);
    public int iss_ref(byte[] pan, int panlen);
    public int acctype_sel();
    public int inc_tsc();
    public int cert_confirm(byte type, byte[] pcon, int len);
    public int lcd_msg(String title, byte[] msg, int len,  int yesno, int waittime);//刚修改char[] 为String
    public int candidate_sel(candidate[] pcan, int amt, int times);
    public int emv_icc_rw(int cardno, byte[] inbuf, int inlen, byte[] outbuf, int olen);
    public int emv_rf_powerdown(int cardno);
    public int emv_ec_switch();
    public int emv_icc_powerup(int[] cardno);  
    public int emv_get_bcdamt(byte ucTransType, byte[] pusBCDCash, byte[] pusBCDCashBack);
    
    public int outcome_msg(ui_request_data msg); 
    public int send_msg(ep_opt epopt);
    public int dek_det(byte mestype, byte[] outbuf, int[] outbuflen);
    
    public int emv_debug(byte[]debuglog, int len);
	public int lcd_msg_new(int msgID, int yesno, int waittime);
	public int language_select(byte[]msg, int len, int yesno, int waittime);
	public int after_final_select(byte[] aid, int aidLen, byte[] usTlvData, int[] nTlvDataLen);
    
//    public int printapdu(byte[]apdu, int len);
    
    
//    /*
//     * String filename：文件名称（包括??径）
//     * int filemode??
//     * #define FILE_READ     1  
//     * #define FILE_WRITE    2   没有的话??动创?? 
//     * 返回值：
//     *失败小于0，否则成??
//     */
//    public int NL_open(String filename, int filemode );
//    /*
//     * 返回值：
//     * 失败小于0，否则成??
//     */
//    public int NL_close(int fd);
//    /*
//     * 读取文件信息
//     * byte[] buffer：数组保存???取的数??
//     * int size：???取的数??长度
//     * 返回值：
//     * 失败小于0，成功返回???取的数??长度
//     */
//    public int NL_read(int fd, byte[] buffer, int size);
//    /*
//     * 写入文件信息
//     * byte[] buffer：???写入的数据
//     * int size：写入的数据长度
//     * 返回值：
//     * 失败小于0，成功返回???取写入的数??长度
//     */
//    public int NL_write(int fd, byte[] buffer, int size);
//    /*
//     * 光标定位
//     * int offset：偏移长??
//     * int where：起始位??
//     * #define FILE_SEEK_SET 0    start of stream 
//	 * #define FILE_SEEK_CUR 1    current position in stream
//     * #define FILE_SEEK_END 2    end of stream  
//     * 返回值：
//     * 失败小于0，成功返回当前光标位??
//     */
//    public int NL_seek(int fd, int offset, int where);
//    /*
//     *文件删减
//     * String filename:文件名称
//     * int size：删减后的长??
//     * 返回值：
//     */
//    public int NL_truncate(String filename, int size);
//    /*
//     *文件删除
//     * String filename:文件名称
//     * 执???成功则返回0?? 失败返回-1
//     */
//    public int NL_delete(String filename);
//    /*
//     *文件重命??
//     * String srcname:源文件名??
//     * String dstname:??标文件名??
//     * 执???成功则返回0?? 失败返回-1
//     */
//    public int NL_rename(String srcname, String dstname);    
}