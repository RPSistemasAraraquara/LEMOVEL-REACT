package sunmi.paylib.adapter.bean;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/29 1:52 下午
 */
public class SPUartParam {
    private static final String TAG = "SPUartParam";

    /**
     * Communication speed The format is: "9600,8,n,1"
     * represents: that the baud rate is 9600bps;
     *             8 data bits;
     *             n:no parity,o:odd parity,e:even parity,m:mark parity,s:space parity;
     *             1 stop bit.
     *  "," will be used to separating characters.
     */
    private String attrSP;
    private EUartPortSP uartPortSP;


    public EUartPortSP getUartPortSP() {
        return uartPortSP;
    }

    public void setUartPortSP(EUartPortSP uartPortSP) {
        this.uartPortSP = uartPortSP;
    }

    public String getAttrSP() {
        return attrSP;
    }

    public void setAttrSP(String attrSP) {
        this.attrSP = attrSP;
    }
}
