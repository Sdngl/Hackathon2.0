import { useState } from "react";
import { Link } from "react-router";
import { LoaderCircle } from "lucide-react";
import { useAdmin } from "../../../context/AdminContext";
import { ALERT_KINDS, RANGE_OPTIONS } from "../../../lib/settings";
import { Card } from "../ui";
import SaveButton from "./SaveButton";
import { SwitchRow } from "./fields";

function DashboardSettingsForm() {
  const { settings, saveSettings, setRangeDays } = useAdmin();
  const [range, setRange] = useState(settings.defaultRange);
  const [kinds, setKinds] = useState(settings.alertKinds);

  const kindsChanged = ALERT_KINDS.some(
    (k) => kinds[k.key] !== settings.alertKinds[k.key],
  );

  return (
    <div className="space-y-5">
      <Card
        title="Default date range"
        subtitle="What the date picker in the top bar starts on"
      >
        <div className="mt-5 flex flex-wrap gap-2">
          {RANGE_OPTIONS.map((days) => (
            <button
              key={days}
              onClick={() => setRange(days)}
              className={`rounded-xl border px-4 py-2.5 text-sm font-medium transition-colors ${
                range === days
                  ? "border-brand-500 bg-brand-50 text-brand-700"
                  : "border-black/10 hover:bg-mist"
              }`}
            >
              Last {days} days
            </button>
          ))}
        </div>
        <div className="mt-5">
          <SaveButton
            disabled={range === settings.defaultRange}
            onSave={async () => {
              await saveSettings({ defaultRange: range });
              setRangeDays(range); // apply it straight away too
            }}
          />
        </div>
      </Card>

      <Card
        title="Notification types"
        subtitle="Which events appear in the Activity feed and count towards the bell badge"
        action={
          <Link
            to="/admin/notifications"
            className="text-sm font-semibold whitespace-nowrap text-brand-700 hover:underline"
          >
            Open Notifications →
          </Link>
        }
      >
        <div className="mt-3 divide-y divide-black/5">
          {ALERT_KINDS.map((k) => (
            <SwitchRow
              key={k.key}
              label={k.label}
              hint={k.hint}
              checked={kinds[k.key] !== false}
              onChange={(on) => setKinds((prev) => ({ ...prev, [k.key]: on }))}
            />
          ))}
        </div>
        <div className="mt-4">
          <SaveButton
            disabled={!kindsChanged}
            onSave={() => saveSettings({ alertKinds: kinds })}
          />
        </div>
      </Card>
    </div>
  );
}

// Settings for how the dashboard behaves for this admin (saved in adminSettings/{uid})
export default function DashboardSettings() {
  const { settingsLoading } = useAdmin();
  // wait for the saved settings, so the form doesn't start from the defaults
  if (settingsLoading)
    return (
      <div className="grid place-items-center py-20">
        <LoaderCircle className="animate-spin text-brand-700" />
      </div>
    );
  return <DashboardSettingsForm />;
}
