type SwalCustomClass = {
  actions?: string;
  cancelButton?: string;
  closeButton?: string;
  confirmButton?: string;
  htmlContainer?: string;
  icon?: string;
  popup?: string;
  title?: string;
};

type SwalOptions = {
  icon?: "success" | "error" | "warning" | "info" | "question";
  title: string;
  text?: string;
  html?: string;
  confirmButtonText?: string;
  cancelButtonText?: string;
  showCancelButton?: boolean;
  buttonsStyling?: boolean;
  showCloseButton?: boolean;
  reverseButtons?: boolean;
  focusConfirm?: boolean;
  background?: string;
  color?: string;
  iconColor?: string;
  backdrop?: boolean | string;
  width?: number | string;
  padding?: number | string;
  customClass?: SwalCustomClass;
};

type SwalLike = {
  fire: (options: SwalOptions) => Promise<unknown>;
};

function getSwal(): SwalLike | null {
  const customWindow = window as Window & { Swal?: SwalLike };
  return customWindow.Swal ?? null;
}

const defaultSwalClasses: SwalCustomClass = {
  popup: "rpfood-swal-popup",
  title: "rpfood-swal-title",
  htmlContainer: "rpfood-swal-text",
  confirmButton: "rpfood-swal-confirm",
  cancelButton: "rpfood-swal-cancel",
  actions: "rpfood-swal-actions",
  closeButton: "rpfood-swal-close",
  icon: "rpfood-swal-icon",
};

function withRpfoodSwalTheme(options: SwalOptions): SwalOptions {
  return {
    confirmButtonText: "OK",
    buttonsStyling: false,
    showCloseButton: true,
    reverseButtons: true,
    focusConfirm: false,
    background: "#fffdf9",
    color: "#23314d",
    backdrop: "rgba(17, 35, 52, 0.5)",
    width: "30rem",
    padding: "0 0 1.5rem",
    ...options,
    customClass: {
      ...defaultSwalClasses,
      ...options.customClass,
    },
  };
}

export async function showLegacySwal(options: SwalOptions): Promise<void> {
  const swal = getSwal();
  if (swal) {
    await swal.fire(withRpfoodSwalTheme(options));
    return;
  }

  window.alert(options.text ?? options.title);
}

export async function showLegacyConfirm(title: string, text: string): Promise<boolean> {
  const swal = getSwal();
  if (swal) {
    const result = (await swal.fire(withRpfoodSwalTheme({
      icon: "question",
      title,
      text,
      confirmButtonText: "Sim, continuar",
      cancelButtonText: "Agora não",
      showCancelButton: true,
      iconColor: "#1b4f72",
    }))) as { isConfirmed?: boolean };
    return Boolean(result?.isConfirmed);
  }

  return window.confirm(text);
}

export async function showLegacyHtmlConfirm(title: string, html: string): Promise<boolean> {
  const swal = getSwal();
  if (swal) {
    const result = (await swal.fire(withRpfoodSwalTheme({
      icon: "question",
      title,
      html,
      confirmButtonText: "Sim, continuar",
      cancelButtonText: "Agora não",
      showCancelButton: true,
      iconColor: "#1b4f72",
    }))) as { isConfirmed?: boolean };
    return Boolean(result?.isConfirmed);
  }

  return window.confirm(title);
}

export async function showLegacyError(title: string, text: string): Promise<void> {
  await showLegacySwal({ icon: "error", title, text, confirmButtonText: "Fechar", iconColor: "#ef5350" });
}

export async function showLegacyWarning(title: string, text: string): Promise<void> {
  await showLegacySwal({ icon: "warning", title, text, confirmButtonText: "Entendi", iconColor: "#f2994a" });
}

export async function showLegacyValidation(title: string, text: string): Promise<void> {
  await showLegacySwal({ icon: "warning", title, text, confirmButtonText: "Entendi", iconColor: "#f2994a" });
}
