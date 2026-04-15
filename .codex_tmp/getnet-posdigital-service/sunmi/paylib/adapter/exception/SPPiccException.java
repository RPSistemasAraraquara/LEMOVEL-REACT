package sunmi.paylib.adapter.exception;

public class SPPiccException extends SPGenericException{
    private int codeError;

    public SPPiccException() {
    }

    public SPPiccException(int codeError) {
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
