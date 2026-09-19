import { useEffect, useMemo } from "react";
import { Download, ExternalLink, FileText, LoaderCircle } from "lucide-react";
import Modal from "../admin/Modal";
import useDocument from "../../hooks/useDocument";
import { useDoctor } from "../../context/DoctorContext";
import { toDate } from "../../lib/dashboardStats";
import { formatDate } from "../../lib/format";
import {
  base64ToObjectUrl,
  findReportFile,
  prettyKey,
  reportDetails,
  reportTitle,
} from "../../lib/reportFiles";

function showValue(value) {
  const date = value?.toDate ? toDate(value) : null;
  if (date) return formatDate(date);
  if (Array.isArray(value))
    return value
      .map((v) => (typeof v === "object" ? JSON.stringify(v) : String(v)))
      .join(", ");
  if (typeof value === "object") return JSON.stringify(value, null, 2);
  if (typeof value === "boolean") return value ? "Yes" : "No";
  return String(value);
}

function FilePreview({ file }) {
  // base64 → temporary blob link; a normal link is used as it is
  const src = useMemo(() => {
    if (!file) return null;
    if (file.url) return file.url;
    try {
      return base64ToObjectUrl(file.base64, file.mime);
    } catch {
      return null;
    }
  }, [file]);

  // free the memory used by the blob link when the pop-up closes
  useEffect(
    () => () => {
      if (src?.startsWith("blob:")) URL.revokeObjectURL(src);
    },
    [src],
  );

  if (!file) {
    return (
      <p className="rounded-2xl bg-mist px-4 py-8 text-center text-sm text-gray-500">
        No file is attached to this report.
      </p>
    );
  }
  if (!src) {
    return (
      <p className="rounded-2xl bg-red-50 px-4 py-6 text-center text-sm text-red-700">
        The file couldn't be opened; it may be damaged.
      </p>
    );
  }

  const isPdf = file.mime === "application/pdf";
  const isImage = file.mime?.startsWith("image/");
  const extension = isPdf
    ? "pdf"
    : (file.mime?.split("/")[1]?.replace("*", "jpg") ?? "file");

  return (
    <div>
      {isPdf ? (
        <iframe
          src={src}
          title="Report PDF"
          className="h-[60vh] w-full rounded-2xl border border-black/10 bg-mist"
        />
      ) : isImage ? (
        <img
          src={src}
          alt="Report scan"
          className="max-h-[60vh] w-full rounded-2xl border border-black/10 bg-mist object-contain"
        />
      ) : (
        <p className="rounded-2xl bg-mist px-4 py-8 text-center text-sm text-gray-500">
          This file type can't be previewed. Download it to open.
        </p>
      )}
      <div className="mt-3 flex flex-wrap gap-2">
        <a
          href={src}
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-1.5 rounded-full border border-black/10 px-4 py-2 text-xs font-semibold hover:bg-mist"
        >
          <ExternalLink size={14} /> Open in new tab
        </a>
        <a
          href={src}
          download={`seva-report.${extension}`}
          className="flex items-center gap-1.5 rounded-full border border-black/10 px-4 py-2 text-xs font-semibold hover:bg-mist"
        >
          <Download size={14} /> Download
        </a>
      </div>
    </div>
  );
}

// Pop-up showing a report a patient shared: users/{userId}/reports/{reportId}
export default function ReportViewer({ appointment, onClose }) {
  const { accessReady } = useDoctor();

  // wait until the access pass exists, otherwise Firestore refuses the first read
  if (!accessReady) {
    return (
      <Modal title="Shared report" onClose={onClose} wide>
        <div className="grid place-items-center py-16">
          <LoaderCircle className="animate-spin text-brand-700" />
        </div>
      </Modal>
    );
  }
  return <ReportBody appointment={appointment} onClose={onClose} />;
}

function ReportBody({ appointment, onClose }) {
  const {
    data: report,
    loading,
    error,
  } = useDocument(`users/${appointment.userId}/reports`, appointment.reportId);
  const file = useMemo(
    () => (report ? findReportFile(report) : null),
    [report],
  );
  const details = useMemo(
    () => (report ? reportDetails(report, file?.field) : []),
    [report, file],
  );

  return (
    <Modal title="Shared report" onClose={onClose} wide>
      <div className="max-h-[75vh] overflow-y-auto pr-1">
        <div className="flex items-start gap-3">
          <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-blue-50 text-blue-600">
            <FileText size={18} />
          </span>
          <div>
            <p className="font-semibold">
              {report ? reportTitle(report) : "Medical report"}
            </p>
            <p className="text-sm text-gray-500">
              From {appointment.patient}
              {appointment.bookedLabel
                ? ` · shared ${appointment.bookedLabel}`
                : ""}
            </p>
          </div>
        </div>

        <div className="mt-5">
          {loading ? (
            <div className="grid place-items-center py-16">
              <LoaderCircle className="animate-spin text-brand-700" />
            </div>
          ) : error ? (
            <p className="rounded-2xl bg-red-50 px-4 py-4 text-sm text-red-700">
              {error.code === "permission-denied"
                ? "You don’t have permission to open this report. The patient may have stopped sharing it."
                : `Couldn't load the report: ${error.message}`}
            </p>
          ) : !report ? (
            <p className="rounded-2xl bg-mist px-4 py-8 text-center text-sm text-gray-500">
              This report no longer exists. The patient may have deleted it.
            </p>
          ) : (
            <>
              <FilePreview file={file} />
              {details.length > 0 && (
                <dl className="mt-5 divide-y divide-black/5 rounded-2xl border border-black/5">
                  {details.map(({ key, value }) => (
                    <div
                      key={key}
                      className="grid grid-cols-[150px_1fr] gap-3 px-4 py-2.5 text-sm"
                    >
                      <dt className="text-gray-500">{prettyKey(key)}</dt>
                      <dd className="font-medium break-words whitespace-pre-wrap">
                        {showValue(value)}
                      </dd>
                    </div>
                  ))}
                </dl>
              )}
            </>
          )}
        </div>

        <p className="mt-4 text-xs text-gray-500">
          Shared by the patient for this appointment. Treat it as confidential
          medical information.
        </p>
      </div>
    </Modal>
  );
}
