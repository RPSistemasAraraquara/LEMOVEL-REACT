package sunmi.paylib.adapter.spiped;

import com.sunmi.pay.hardware.aidl.bean.EKeyCodeSP;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/9/26 10:45 上午
 */
public interface SPIPedInputPinListener {

    public void onKeyEventSP(EKeyCodeSP keyCode);

}
