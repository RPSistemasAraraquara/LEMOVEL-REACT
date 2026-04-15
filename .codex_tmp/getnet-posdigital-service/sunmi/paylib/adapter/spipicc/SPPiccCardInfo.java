package sunmi.paylib.adapter.spipicc;

public class SPPiccCardInfo {
    private byte cardTypeSP;
    private byte CidSP;
    private byte[] otherSP;
    private byte[] serialInfoSP;

    public SPPiccCardInfo() {
    }

    public SPPiccCardInfo(byte cardTypeSP, byte cidSP, byte[] otherSP, byte[] serialInfoSP) {
        this.cardTypeSP = cardTypeSP;
        CidSP = cidSP;
        this.otherSP = otherSP;
        this.serialInfoSP = serialInfoSP;
    }

    public byte getCardTypeSP() {
        return cardTypeSP;
    }

    public void setCardTypeSP(byte cardTypeSP) {
        this.cardTypeSP = cardTypeSP;
    }

    public byte getCidSP() {
        return CidSP;
    }

    public void setCidSP(byte cidSP) {
        CidSP = cidSP;
    }

    public byte[] getOtherSP() {
        return otherSP;
    }

    public void setOtherSP(byte[] otherSP) {
        this.otherSP = otherSP;
    }

    public byte[] getSerialInfoSP() {
        return serialInfoSP;
    }

    public void setSerialInfoSP(byte[] serialInfoSP) {
        this.serialInfoSP = serialInfoSP;
    }
}
