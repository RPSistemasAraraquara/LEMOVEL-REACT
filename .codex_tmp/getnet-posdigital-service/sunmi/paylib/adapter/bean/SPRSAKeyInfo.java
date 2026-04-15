package sunmi.paylib.adapter.bean;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/9/20 5:04 下午
 */
public class SPRSAKeyInfo {
    private static final String TAG = "SPRSAKeyInfo";

    byte[] exponentSP;

    byte[] modulusSP;

    byte[] keyInfoSP;

    int modulusLenSP;

    int exponentLenSP;

    public byte[] getExponentSP() {
        return exponentSP;
    }

    public void setExponentSP(byte[] exponentSP) {
        this.exponentSP = exponentSP;
    }

    public byte[] getModulusSP() {
        return modulusSP;
    }

    public void setModulusSP(byte[] modulusSP) {
        this.modulusSP = modulusSP;
    }

    public byte[] getKeyInfoSP() {
        return keyInfoSP;
    }

    public void setKeyInfoSP(byte[] keyInfoSP) {
        this.keyInfoSP = keyInfoSP;
    }

    public int getModulusLenSP() {
        return modulusLenSP;
    }

    public void setModulusLenSP(int modulusLenSP) {
        this.modulusLenSP = modulusLenSP;
    }

    public int getExponentLenSP() {
        return exponentLenSP;
    }

    public void setExponentLenSP(int exponentLenSP) {
        this.exponentLenSP = exponentLenSP;
    }
}
