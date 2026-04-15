package sunmi.paylib.adapter.spicomm.apn;

import java.util.Objects;

public class SPApnInfo {
    private String apnCarrierSP;        //name
    private String apnSP;               //apn
    private int authtypeSP;             //authtype
    private String mccSP;           //mcc
    private String mmscSP;          //mmsc
    private String mmsportSP;       //mmsport
    private String mmsProxySP;      //mmsproxy
    private String mncSP;           //mnc
    private String passwordSP;      //password
    private String portSP;          //port
    private String protocolSP;      //protocol
    private String proxySP;         //proxy
    private String roamingProtocolSP;   //roaming_protocol
    private String serverSP;        //server
    private String typeSP;          //type
    private String userSP;          //user
    private String apnIdSP;

    public String getApnCarrierSP() {
        return apnCarrierSP;
    }

    public void setApnCarrierSP(String apnCarrierSP) {
        this.apnCarrierSP = apnCarrierSP;
    }

    public String getApnSP() {
        return apnSP;
    }

    public void setApnSP(String apnSP) {
        this.apnSP = apnSP;
    }

    public int getAuthtypeSP() {
        return authtypeSP;
    }

    public void setAuthtypeSP(int authtypeSP) {
        this.authtypeSP = authtypeSP;
    }

    public String getMccSP() {
        return mccSP;
    }

    public void setMccSP(String mccSP) {
        this.mccSP = mccSP;
    }

    public String getMmscSP() {
        return mmscSP;
    }

    public void setMmscSP(String mmscSP) {
        this.mmscSP = mmscSP;
    }

    public String getMmsportSP() {
        return mmsportSP;
    }

    public void setMmsportSP(String mmsportSP) {
        this.mmsportSP = mmsportSP;
    }

    public String getMmsProxySP() {
        return mmsProxySP;
    }

    public void setMmsProxySP(String mmsProxySP) {
        this.mmsProxySP = mmsProxySP;
    }

    public String getMncSP() {
        return mncSP;
    }

    public void setMncSP(String mncSP) {
        this.mncSP = mncSP;
    }

    public String getPasswordSP() {
        return passwordSP;
    }

    public void setPasswordSP(String passwordSP) {
        this.passwordSP = passwordSP;
    }

    public String getPortSP() {
        return portSP;
    }

    public void setPortSP(String portSP) {
        this.portSP = portSP;
    }

    public String getProtocolSP() {
        return protocolSP;
    }

    public void setProtocolSP(String protocolSP) {
        this.protocolSP = protocolSP;
    }

    public String getProxySP() {
        return proxySP;
    }

    public void setProxySP(String proxySP) {
        this.proxySP = proxySP;
    }

    public String getRoamingProtocolSP() {
        return roamingProtocolSP;
    }

    public void setRoamingProtocolSP(String roamingProtocolSP) {
        this.roamingProtocolSP = roamingProtocolSP;
    }

    public String getServerSP() {
        return serverSP;
    }

    public void setServerSP(String serverSP) {
        this.serverSP = serverSP;
    }

    public String getTypeSP() {
        return typeSP;
    }

    public void setTypeSP(String typeSP) {
        this.typeSP = typeSP;
    }

    public String getUserSP() {
        return userSP;
    }

    public void setUserSP(String userSP) {
        this.userSP = userSP;
    }

    @Override
    public String toString() {
        return "SPApnInfo{" +
                "apnCarrierSP='" + apnCarrierSP + '\'' +
                ", apnSP='" + apnSP + '\'' +
                ", authtypeSP=" + authtypeSP +
                ", mccSP='" + mccSP + '\'' +
                ", mmscSP='" + mmscSP + '\'' +
                ", mmsportSP='" + mmsportSP + '\'' +
                ", mmsProxySP='" + mmsProxySP + '\'' +
                ", mncSP='" + mncSP + '\'' +
                ", passwordSP='" + passwordSP + '\'' +
                ", portSP='" + portSP + '\'' +
                ", protocolSP='" + protocolSP + '\'' +
                ", proxySP='" + proxySP + '\'' +
                ", roamingProtocolSP='" + roamingProtocolSP + '\'' +
                ", serverSP='" + serverSP + '\'' +
                ", typeSP='" + typeSP + '\'' +
                ", userSP='" + userSP + '\'' +
                ", apnIdSP='" + apnIdSP + '\'' +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        SPApnInfo spApnInfo = (SPApnInfo) o;
        return authtypeSP == spApnInfo.authtypeSP && Objects.equals(apnCarrierSP, spApnInfo.apnCarrierSP) && Objects.equals(apnSP, spApnInfo.apnSP) && Objects.equals(mccSP, spApnInfo.mccSP) && Objects.equals(mmscSP, spApnInfo.mmscSP) && Objects.equals(mmsportSP, spApnInfo.mmsportSP) && Objects.equals(mmsProxySP, spApnInfo.mmsProxySP) && Objects.equals(mncSP, spApnInfo.mncSP) && Objects.equals(passwordSP, spApnInfo.passwordSP) && Objects.equals(portSP, spApnInfo.portSP) && Objects.equals(protocolSP, spApnInfo.protocolSP) && Objects.equals(proxySP, spApnInfo.proxySP) && Objects.equals(roamingProtocolSP, spApnInfo.roamingProtocolSP) && Objects.equals(serverSP, spApnInfo.serverSP) && Objects.equals(typeSP, spApnInfo.typeSP) && Objects.equals(userSP, spApnInfo.userSP);
    }

    @Override
    public int hashCode() {
        return Objects.hash(apnCarrierSP, apnSP, authtypeSP, mccSP, mmscSP, mmsportSP, mmsProxySP, mncSP, passwordSP, portSP, protocolSP, proxySP, roamingProtocolSP, serverSP, typeSP, userSP);
    }

    public String getApnIdSP() {
        return apnIdSP;
    }

    public void setApnIdSP(String apnIdSP) {
        this.apnIdSP = apnIdSP;
    }
}
