import { Elm } from "./Main.elm";

type Tracking = {
  date: string;
  shifts: Shift[];
};

type Shift = {
  start: string;
  end: string;
};

const app = Elm.Main.init({
  node: document.getElementById("app"),
});

const tickWorker = new Worker(new URL("./tickWorker.js", import.meta.url));

tickWorker.onmessage = (event: MessageEvent<number>) => {
  app.ports.ticked.send(event.data);
};

app.ports.setPageTitle.subscribe((title: string) => {
  document.title = title;
});

app.ports.save.subscribe((tracking: Tracking) => {
  localStorage.setItem(tracking.date, JSON.stringify(tracking.shifts));
});

app.ports.load.subscribe((date: string) => {
  const shiftsStr = localStorage.getItem(date);
  try {
    const shifts: Shift[] = JSON.parse(shiftsStr || "{}");

    app.ports.gotShifts.send(shifts);
  } catch {
    app.ports.gotShifts.send([]);
  }
});
