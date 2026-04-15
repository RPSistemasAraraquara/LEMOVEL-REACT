package sunmi.paylib.adapter;

/**
 * @Desc 初始化检查基类
 * @Author blanks
 * @Date 2022/7/21 3:06 下午
 */
public class Base {
    private static final String TAG = "Base";

    public boolean isInit = false;

    public void checkInit(){
        if (!isInit){
            throw new RuntimeException("The current module is not initialized and cannot be used");
        }
    }


}
