package sunmi.paylib.adapter.spicomm;


import sunmi.paylib.adapter.spicomm.driver.CdcAcmSerialDriver;
import sunmi.paylib.adapter.spicomm.driver.ProbeTable;
import sunmi.paylib.adapter.spicomm.driver.UsbSerialProber;

public class RS232CustomProbe {

    public static UsbSerialProber getCustomProbe() {
        ProbeTable customTable = new ProbeTable();
        customTable.addProduct(0x16d0, 0x087e, CdcAcmSerialDriver.class);
        customTable.addProduct(0x067b, 0x23c3, CdcAcmSerialDriver.class);
        return new UsbSerialProber(customTable);
    }

}
