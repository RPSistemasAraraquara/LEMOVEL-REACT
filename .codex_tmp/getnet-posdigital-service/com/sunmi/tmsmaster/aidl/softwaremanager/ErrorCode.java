package com.sunmi.tmsmaster.aidl.softwaremanager;

public interface ErrorCode {
    /**
     * 默认失败
     */
    int ERROR_PACKAGE_INSTALL_FAILED                   = -100;
    /**
     * 非法的apk类型
     */
    int ERROR_PACKAGE_INSTALL_FAILED_INVALID_APK       = -101;
    /**
     * 安装权限不足
     */
    int ERROR_PACKAGE_INSTALL_FAILED_PERMISSION_FAILED = -102;
    /**
     * 空间不足
     */
    int ERROR_PACKAGE_INSTALL_FAILED_NO_SPACE          = -103;
    /**
     * 签名信息错误
     */
    int ERROR_PACKAGE_INSTALL_FAILED_SIGNATURE_FAILED  = -104;
    /**
     * 已安装了更高版本的同名数据包
     */
    int ERROR_PACKAGE_INSTALL_FAILED_VERSION_DOWNGRADE = -107;
    /**
     * 默认失败
     */
    int ERROR_PACKAGE_DELETE_FAILED                    = -200;
    /**
     * 默认失败，卸载app找不到
     */
    int ERROR_PACKAGE_DELETE_FAILED_APP_NOT_FOUND      = -201;
    /**
     * 默认失败，权限不足
     */
    int ERROR_PACKAGE_DELETE_FAILED_NO_PERMISSION      = -202;
    /**
     * 存在相同版本
     */
    int ERROR_PACKAGE_INSTALL_FAILED_ALREADY_EXIST     = -111;
}
