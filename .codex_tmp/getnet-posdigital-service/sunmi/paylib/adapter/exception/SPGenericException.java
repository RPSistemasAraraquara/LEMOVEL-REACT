package sunmi.paylib.adapter.exception;

import java.io.Serializable;

public class SPGenericException extends Exception implements Serializable {
    private int codeError;

    public SPGenericException() {
    }

    public SPGenericException(int codeError) {
        this.codeError = codeError;
    }

    public int getCodeError() {
        return codeError;
    }

    public void setCodeError(int codeError) {
        this.codeError = codeError;
    }
}
