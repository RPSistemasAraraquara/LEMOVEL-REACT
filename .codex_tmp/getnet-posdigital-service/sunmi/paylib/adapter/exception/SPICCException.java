package sunmi.paylib.adapter.exception;

public class SPICCException extends SPGenericException{
    private int codeError;

    public SPICCException() {
    }

    public SPICCException(int codeError) {
        this.codeError = codeError;
    }

    @Override
    public int getCodeError() {
        return codeError;
    }

    @Override
    public void setCodeError(int codeError) {
        this.codeError = codeError;
    }
}
