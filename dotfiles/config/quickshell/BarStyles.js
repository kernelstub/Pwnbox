.pragma library


function geometry(name, barHeight, bgA) {
    switch (name) {
    case "floating":
        return { file: "02", height: 48, color: "transparent", exclusive: 38, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    case "flat":
        return { file: "03", height: 28, color: bgA, exclusive: 28, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    case "pill":
        return { file: "04", height: 54, color: "transparent", exclusive: 46, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    case "capsule":
        return { file: "05", height: 50, color: "transparent", exclusive: 42, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    case "bottom":
        return { file: "06", height: 48, color: "transparent", exclusive: 40, top: false, bottom: true, left: true, right: true, vertical: false, clock: "center" };
    case "split":
        return { file: "07", height: 56, color: "transparent", exclusive: 38, top: true, bottom: false, left: true, right: true, vertical: false, clock: "right" };
    case "blocky":
        return { file: "08", height: 34, color: bgA, exclusive: 34, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    case "minipills":
        return { file: "10", height: 50, color: "transparent", exclusive: 38, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    case "side":
        return { file: "11", width: 52, color: bgA, exclusive: 52, top: true, bottom: true, left: true, right: false, vertical: true, clock: "center" };
    case "sideright":
        return { file: "12", width: 52, color: bgA, exclusive: 52, top: true, bottom: true, left: false, right: true, vertical: true, clock: "center" };
    case "sidepill":
        return { file: "13", width: 48, color: "transparent", exclusive: 44, top: true, bottom: true, left: true, right: false, vertical: true, clock: "center" };
    case "sidepillright":
        return { file: "14", width: 48, color: "transparent", exclusive: 44, top: true, bottom: true, left: false, right: true, vertical: true, clock: "center" };
    case "sideminipills":
        return { file: "17", width: 44, color: "transparent", exclusive: 40, top: true, bottom: true, left: true, right: false, vertical: true, clock: "center" };
    case "sideminipillsright":
        return { file: "18", width: 44, color: "transparent", exclusive: 40, top: true, bottom: true, left: false, right: true, vertical: true, clock: "center" };
    default:
        return { file: "01", height: barHeight, color: bgA, exclusive: barHeight, top: true, bottom: false, left: true, right: true, vertical: false, clock: "center" };
    }
}
