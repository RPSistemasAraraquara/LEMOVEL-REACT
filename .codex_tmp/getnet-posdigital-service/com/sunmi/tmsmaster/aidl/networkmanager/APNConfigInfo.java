package com.sunmi.tmsmaster.aidl.networkmanager;

import android.os.Parcel;
import android.os.Parcelable;

public class APNConfigInfo implements Parcelable {
    private String _id = null;
    private String name = null;
    private String numeric = null;
    private String mcc = null;
    private String mnc = null;
    private String apn = null;
    private String user = null;
    private String server = null;
    private String password = null;
    private String proxy = null;
    private String port = null;
    private String mmsproxy = null;
    private String mmsport = null;
    private String mmsc = null;
    private String authtype = null;
    private String type = null;
    private String current = null;
    private String sourcetype = null;
    private String csdnum = null;
    private String protocol = null;
    private String roaming_protocol = null;
    private String omacpid = null;
    private String napid = null;
    private String proxyid = null;
    private String carrier_enabled = null;
    private String bearer = null;
    private String bearer_bitmask = null;
    private String network_type_bitmask = null;
    private String spn = null;
    private String imsi = null;
    private String pnn = null;
    private String ppp = null;
    private String mvno_type = null;
    private String mvno_match_data = null;
    private String sub_id = null;
    private String profile_id = null;
    private String modem_cognitive = null;
    private String max_conns = null;
    private String wait_time = null;
    private String max_conns_time = null;
    private String mtu = null;
    private String edited = null;
    private String user_visible = null;
    private String user_editable = null;
    private String owned_by = null;
    private String apn_set_id = null;

    public APNConfigInfo() {
    }

    protected APNConfigInfo(Parcel in) {
        name = in.readString();
        apn = in.readString();
        type = in.readString();
        proxy = in.readString();
        port = in.readString();
        mmsproxy = in.readString();
        mmsport = in.readString();
        user = in.readString();
        server = in.readString();
        password = in.readString();
        mnc = in.readString();
        mmsc = in.readString();
        authtype = in.readString();
        this._id = in.readString();
        this.numeric = in.readString();
        this.mcc = in.readString();
        this.current = in.readString();
        this.sourcetype = in.readString();
        this.csdnum = in.readString();
        this.protocol = in.readString();
        this.roaming_protocol = in.readString();
        this.omacpid = in.readString();
        this.napid = in.readString();
        this.proxyid = in.readString();
        this.carrier_enabled = in.readString();
        this.bearer = in.readString();
        this.bearer_bitmask = in.readString();
        this.network_type_bitmask = in.readString();
        this.spn = in.readString();
        this.imsi = in.readString();
        this.pnn = in.readString();
        this.ppp = in.readString();
        this.mvno_type = in.readString();
        this.mvno_match_data = in.readString();
        this.sub_id = in.readString();
        this.profile_id = in.readString();
        this.modem_cognitive = in.readString();
        this.max_conns = in.readString();
        this.wait_time = in.readString();
        this.max_conns_time = in.readString();
        this.mtu = in.readString();
        this.edited = in.readString();
        this.user_visible = in.readString();
        this.user_editable = in.readString();
        this.owned_by = in.readString();
        this.apn_set_id = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(name);
        dest.writeString(apn);
        dest.writeString(type);
        dest.writeString(proxy);
        dest.writeString(port);
        dest.writeString(mmsproxy);
        dest.writeString(mmsport);
        dest.writeString(user);
        dest.writeString(server);
        dest.writeString(password);
        dest.writeString(mnc);
        dest.writeString(mmsc);
        dest.writeString(authtype);
        dest.writeString(this._id);
        dest.writeString(this.numeric);
        dest.writeString(this.mcc);
        dest.writeString(this.current);
        dest.writeString(this.sourcetype);
        dest.writeString(this.csdnum);
        dest.writeString(this.protocol);
        dest.writeString(this.roaming_protocol);
        dest.writeString(this.omacpid);
        dest.writeString(this.napid);
        dest.writeString(this.proxyid);
        dest.writeString(this.carrier_enabled);
        dest.writeString(this.bearer);
        dest.writeString(this.bearer_bitmask);
        dest.writeString(this.network_type_bitmask);
        dest.writeString(this.spn);
        dest.writeString(this.imsi);
        dest.writeString(this.pnn);
        dest.writeString(this.ppp);
        dest.writeString(this.mvno_type);
        dest.writeString(this.mvno_match_data);
        dest.writeString(this.sub_id);
        dest.writeString(this.profile_id);
        dest.writeString(this.modem_cognitive);
        dest.writeString(this.max_conns);
        dest.writeString(this.wait_time);
        dest.writeString(this.max_conns_time);
        dest.writeString(this.mtu);
        dest.writeString(this.edited);
        dest.writeString(this.user_visible);
        dest.writeString(this.user_editable);
        dest.writeString(this.owned_by);
        dest.writeString(this.apn_set_id);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public void readFromParcel(Parcel source) {
        this._id = source.readString();
        this.name = source.readString();
        this.numeric = source.readString();
        this.mcc = source.readString();
        this.mnc = source.readString();
        this.apn = source.readString();
        this.user = source.readString();
        this.server = source.readString();
        this.password = source.readString();
        this.proxy = source.readString();
        this.port = source.readString();
        this.mmsproxy = source.readString();
        this.mmsport = source.readString();
        this.mmsc = source.readString();
        this.authtype = source.readString();
        this.type = source.readString();
        this.current = source.readString();
        this.sourcetype = source.readString();
        this.csdnum = source.readString();
        this.protocol = source.readString();
        this.roaming_protocol = source.readString();
        this.omacpid = source.readString();
        this.napid = source.readString();
        this.proxyid = source.readString();
        this.carrier_enabled = source.readString();
        this.bearer = source.readString();
        this.bearer_bitmask = source.readString();
        this.network_type_bitmask = source.readString();
        this.spn = source.readString();
        this.imsi = source.readString();
        this.pnn = source.readString();
        this.ppp = source.readString();
        this.mvno_type = source.readString();
        this.mvno_match_data = source.readString();
        this.sub_id = source.readString();
        this.profile_id = source.readString();
        this.modem_cognitive = source.readString();
        this.max_conns = source.readString();
        this.wait_time = source.readString();
        this.max_conns_time = source.readString();
        this.mtu = source.readString();
        this.edited = source.readString();
        this.user_visible = source.readString();
        this.user_editable = source.readString();
        this.owned_by = source.readString();
        this.apn_set_id = source.readString();
    }



    public static final Creator<APNConfigInfo> CREATOR = new Creator<APNConfigInfo>() {
        @Override
        public APNConfigInfo createFromParcel(Parcel in) {
            return new APNConfigInfo(in);
        }

        @Override
        public APNConfigInfo[] newArray(int size) {
            return new APNConfigInfo[size];
        }
    };

    public String get_id() {
        return _id;
    }

    public void set_id(String _id) {
        this._id = _id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getNumeric() {
        return numeric;
    }

    public void setNumeric(String numeric) {
        this.numeric = numeric;
    }

    public String getMcc() {
        return mcc;
    }

    public void setMcc(String mcc) {
        this.mcc = mcc;
    }

    public String getMnc() {
        return mnc;
    }

    public void setMnc(String mnc) {
        this.mnc = mnc;
    }

    public String getApn() {
        return apn;
    }

    public void setApn(String apn) {
        this.apn = apn;
    }

    public String getUser() {
        return user;
    }

    public void setUser(String user) {
        this.user = user;
    }

    public String getServer() {
        return server;
    }

    public void setServer(String server) {
        this.server = server;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getProxy() {
        return proxy;
    }

    public void setProxy(String proxy) {
        this.proxy = proxy;
    }

    public String getPort() {
        return port;
    }

    public void setPort(String port) {
        this.port = port;
    }

    public String getMmsproxy() {
        return mmsproxy;
    }

    public void setMmsproxy(String mmsproxy) {
        this.mmsproxy = mmsproxy;
    }

    public String getMmsport() {
        return mmsport;
    }

    public void setMmsport(String mmsport) {
        this.mmsport = mmsport;
    }

    public String getMmsc() {
        return mmsc;
    }

    public void setMmsc(String mmsc) {
        this.mmsc = mmsc;
    }

    public String getAuthtype() {
        return authtype;
    }

    public void setAuthtype(String authtype) {
        this.authtype = authtype;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getCurrent() {
        return current;
    }

    public void setCurrent(String current) {
        this.current = current;
    }

    public String getSourcetype() {
        return sourcetype;
    }

    public void setSourcetype(String sourcetype) {
        this.sourcetype = sourcetype;
    }

    public String getCsdnum() {
        return csdnum;
    }

    public void setCsdnum(String csdnum) {
        this.csdnum = csdnum;
    }

    public String getProtocol() {
        return protocol;
    }

    public void setProtocol(String protocol) {
        this.protocol = protocol;
    }

    public String getRoaming_protocol() {
        return roaming_protocol;
    }

    public void setRoaming_protocol(String roaming_protocol) {
        this.roaming_protocol = roaming_protocol;
    }

    public String getOmacpid() {
        return omacpid;
    }

    public void setOmacpid(String omacpid) {
        this.omacpid = omacpid;
    }

    public String getNapid() {
        return napid;
    }

    public void setNapid(String napid) {
        this.napid = napid;
    }

    public String getProxyid() {
        return proxyid;
    }

    public void setProxyid(String proxyid) {
        this.proxyid = proxyid;
    }

    public String getCarrier_enabled() {
        return carrier_enabled;
    }

    public void setCarrier_enabled(String carrier_enabled) {
        this.carrier_enabled = carrier_enabled;
    }

    public String getBearer() {
        return bearer;
    }

    public void setBearer(String bearer) {
        this.bearer = bearer;
    }

    public String getBearer_bitmask() {
        return bearer_bitmask;
    }

    public void setBearer_bitmask(String bearer_bitmask) {
        this.bearer_bitmask = bearer_bitmask;
    }

    public String getNetwork_type_bitmask() {
        return network_type_bitmask;
    }

    public void setNetwork_type_bitmask(String network_type_bitmask) {
        this.network_type_bitmask = network_type_bitmask;
    }

    public String getSpn() {
        return spn;
    }

    public void setSpn(String spn) {
        this.spn = spn;
    }

    public String getImsi() {
        return imsi;
    }

    public void setImsi(String imsi) {
        this.imsi = imsi;
    }

    public String getPnn() {
        return pnn;
    }

    public void setPnn(String pnn) {
        this.pnn = pnn;
    }

    public String getPpp() {
        return ppp;
    }

    public void setPpp(String ppp) {
        this.ppp = ppp;
    }

    public String getMvno_type() {
        return mvno_type;
    }

    public void setMvno_type(String mvno_type) {
        this.mvno_type = mvno_type;
    }

    public String getMvno_match_data() {
        return mvno_match_data;
    }

    public void setMvno_match_data(String mvno_match_data) {
        this.mvno_match_data = mvno_match_data;
    }

    public String getSub_id() {
        return sub_id;
    }

    public void setSub_id(String sub_id) {
        this.sub_id = sub_id;
    }

    public String getProfile_id() {
        return profile_id;
    }

    public void setProfile_id(String profile_id) {
        this.profile_id = profile_id;
    }

    public String getModem_cognitive() {
        return modem_cognitive;
    }

    public void setModem_cognitive(String modem_cognitive) {
        this.modem_cognitive = modem_cognitive;
    }

    public String getMax_conns() {
        return max_conns;
    }

    public void setMax_conns(String max_conns) {
        this.max_conns = max_conns;
    }

    public String getWait_time() {
        return wait_time;
    }

    public void setWait_time(String wait_time) {
        this.wait_time = wait_time;
    }

    public String getMax_conns_time() {
        return max_conns_time;
    }

    public void setMax_conns_time(String max_conns_time) {
        this.max_conns_time = max_conns_time;
    }

    public String getMtu() {
        return mtu;
    }

    public void setMtu(String mtu) {
        this.mtu = mtu;
    }

    public String getEdited() {
        return edited;
    }

    public void setEdited(String edited) {
        this.edited = edited;
    }

    public String getUser_visible() {
        return user_visible;
    }

    public void setUser_visible(String user_visible) {
        this.user_visible = user_visible;
    }

    public String getUser_editable() {
        return user_editable;
    }

    public void setUser_editable(String user_editable) {
        this.user_editable = user_editable;
    }

    public String getOwned_by() {
        return owned_by;
    }

    public void setOwned_by(String owned_by) {
        this.owned_by = owned_by;
    }

    public String getApn_set_id() {
        return apn_set_id;
    }

    public void setApn_set_id(String apn_set_id) {
        this.apn_set_id = apn_set_id;
    }

    public static Creator<APNConfigInfo> getCREATOR() {
        return CREATOR;
    }

    @Override
    public String toString() {
        return "APNConfigInfo{" +
                "_id='" + _id + '\'' +
                ", name='" + name + '\'' +
                ", numeric='" + numeric + '\'' +
                ", mcc='" + mcc + '\'' +
                ", mnc='" + mnc + '\'' +
                ", apn='" + apn + '\'' +
                ", user='" + user + '\'' +
                ", server='" + server + '\'' +
                ", password='" + password + '\'' +
                ", proxy='" + proxy + '\'' +
                ", port='" + port + '\'' +
                ", mmsproxy='" + mmsproxy + '\'' +
                ", mmsport='" + mmsport + '\'' +
                ", mmsc='" + mmsc + '\'' +
                ", authtype='" + authtype + '\'' +
                ", type='" + type + '\'' +
                ", current='" + current + '\'' +
                ", sourcetype='" + sourcetype + '\'' +
                ", csdnum='" + csdnum + '\'' +
                ", protocol='" + protocol + '\'' +
                ", roaming_protocol='" + roaming_protocol + '\'' +
                ", omacpid='" + omacpid + '\'' +
                ", napid='" + napid + '\'' +
                ", proxyid='" + proxyid + '\'' +
                ", carrier_enabled='" + carrier_enabled + '\'' +
                ", bearer='" + bearer + '\'' +
                ", bearer_bitmask='" + bearer_bitmask + '\'' +
                ", network_type_bitmask='" + network_type_bitmask + '\'' +
                ", spn='" + spn + '\'' +
                ", imsi='" + imsi + '\'' +
                ", pnn='" + pnn + '\'' +
                ", ppp='" + ppp + '\'' +
                ", mvno_type='" + mvno_type + '\'' +
                ", mvno_match_data='" + mvno_match_data + '\'' +
                ", sub_id='" + sub_id + '\'' +
                ", profile_id='" + profile_id + '\'' +
                ", modem_cognitive='" + modem_cognitive + '\'' +
                ", max_conns='" + max_conns + '\'' +
                ", wait_time='" + wait_time + '\'' +
                ", max_conns_time='" + max_conns_time + '\'' +
                ", mtu='" + mtu + '\'' +
                ", edited='" + edited + '\'' +
                ", user_visible='" + user_visible + '\'' +
                ", user_editable='" + user_editable + '\'' +
                ", owned_by='" + owned_by + '\'' +
                ", apn_set_id='" + apn_set_id + '\'' +
                '}';
    }
}
