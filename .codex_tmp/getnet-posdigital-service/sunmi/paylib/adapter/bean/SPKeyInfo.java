package sunmi.paylib.adapter.bean;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/9/22 11:25 上午
 */
public class SPKeyInfo {
    private static final String TAG = "SPKeyInfo";

    byte[] kcvSP;
    byte keyIndexSP;
    short keyLenSP;
    byte keyTypeSP;
    byte[] ksnSP;

    public byte[] getKcvSP() {
        return kcvSP;
    }

    public void setKcvSP(byte[] kcvSP) {
        this.kcvSP = kcvSP;
    }

    public byte getKeyIndexSP() {
        return keyIndexSP;
    }

    public void setKeyIndexSP(byte keyIndexSP) {
        this.keyIndexSP = keyIndexSP;
    }

    public short getKeyLenSP() {
        return keyLenSP;
    }

    public void setKeyLenSP(short keyLenSP) {
        this.keyLenSP = keyLenSP;
    }

    public byte getKeyTypeSP() {
        return keyTypeSP;
    }

    public void setKeyTypeSP(byte keyTypeSP) {
        this.keyTypeSP = keyTypeSP;
    }

    public byte[] getKsnSP() {
        return ksnSP;
    }

    public void setKsnSP(byte[] ksnSP) {
        this.ksnSP = ksnSP;
    }
}
