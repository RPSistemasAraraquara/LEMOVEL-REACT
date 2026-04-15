package sunmi.paylib.adapter.spicomm.util;

import android.app.ActivityManager;
import android.content.Context;

import java.util.List;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/8/2 2:38 下午
 */
public class COMMUtil {
    private static final String TAG = "COMMUtil";

    public static String getAppProcessName(Context context) {
        //当前应用pid
        int pid = android.os.Process.myPid();
        //任务管理类
        ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        //遍历所有应用
        List<ActivityManager.RunningAppProcessInfo> infos = manager.getRunningAppProcesses();
        for (ActivityManager.RunningAppProcessInfo info : infos) {
            if (info.pid == pid)//得到当前应用
                return info.processName;//返回包名
        }
        return "";
    }


}
