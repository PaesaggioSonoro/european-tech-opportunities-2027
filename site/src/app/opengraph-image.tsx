import {ImageResponse} from "next/og";
import {siteConfig} from "@/lib/site-config";

export const alt = `${siteConfig.name} directory`;
export const size = {width: 1200, height: 630};
export const contentType = "image/png";

function createSeededRandom(seed: number) {
  let state = seed;

  return () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

function createBackgroundPoints(count: number) {
  // Stable pseudo-random placement prevents social-card output changing between builds.
  const random = createSeededRandom(2027);

  return Array.from({length: count}, (_, id) => ({
    id,
    left: random() * 100,
    top: random() * 100,
    size: 1 + random() * 3,
    opacity: 0.3 + random() * 0.55,
  }));
}

const backgroundPoints = createBackgroundPoints(56);

export default function OpenGraphImage() {
  return new ImageResponse(
    <div
      style={{
        alignItems: "center",
        background: "#000000",
        color: "white",
        display: "flex",
        height: "100%",
        justifyContent: "center",
        overflow: "hidden",
        padding: "72px",
        position: "relative",
        width: "100%",
      }}
    >
      {backgroundPoints.map((point) => (
        <div
          key={point.id}
          style={{
            background: "#ffffff",
            borderRadius: "999px",
            height: `${point.size}px`,
            left: `${point.left}%`,
            opacity: point.opacity,
            position: "absolute",
            top: `${point.top}%`,
            width: `${point.size}px`,
          }}
        />
      ))}
      <div
        style={{
          border: "2px solid rgba(255,255,255,0.24)",
          borderRadius: "36px",
          display: "flex",
          flexDirection: "column",
          gap: "30px",
          padding: "70px",
          position: "relative",
          transform: "translateY(-20px)",
          width: "100%",
        }}
      >
        <div style={{display: "flex", fontSize: 72, fontWeight: 700, lineHeight: 1.05}}>
          {siteConfig.name}
        </div>
        <div style={{color: "#dce8ff", display: "flex", fontSize: 32}}>
          {siteConfig.description}
        </div>
      </div>
    </div>,
    size
  );
}
