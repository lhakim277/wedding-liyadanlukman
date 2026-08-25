"use client";

import Image from "next/image";
import { useSearchParams } from "next/navigation";
import {
  FormEvent,
  Suspense,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import styles from "./wedding.module.css";

const MAPS_URL = "https://maps.app.goo.gl/srjDJdPtuWnAgVXm8";
const MAPS_URL_RESEPSI = "https://maps.app.goo.gl/dUms5Z9cxpoVXWvk7";
const WEDDING_TARGET = new Date("2026-09-06T08:00:00+07:00").getTime();
const BANK_ACC = "7645012976";
const BANK_NAME_LUKMAN = "Lukman Hakim";
const BANK_NAME_IBU = "Siti Nurfaidah";
const GIFT_ADDRESS =
  "Jl. M. Siban Bojong Poncol No.172, RT.002/RW.008, Kunciran Indah, Kec. Pinang, Kota Tangerang, Banten 15144";
const WISHES_KEY = "liya-lukman-wishes";

type Wish = { name: string; message: string; at: number };

function pad(n: number) {
  return String(n).padStart(2, "0");
}

function useGuestName() {
  const searchParams = useSearchParams();
  const raw = searchParams.get("to");
  if (!raw) return "Tamu Undangan";
  return decodeURIComponent(raw).replace(/\+/g, " ");
}

function WeddingInvitation() {
  const guestName = useGuestName();
  const [opened, setOpened] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [rsvpStatus, setRsvpStatus] = useState<"yes" | "no" | null>(null);
  const [cd, setCd] = useState({ d: "00", h: "00", m: "00", s: "00" });
  const [wishName, setWishName] = useState("");
  const [wishMessage, setWishMessage] = useState("");
  const [wishes, setWishes] = useState<Wish[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [lightboxImg, setLightboxImg] = useState<string | null>(null);

  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    document.body.classList.add("invite-locked");
    try {
      const raw = localStorage.getItem(WISHES_KEY);
      if (raw) {
        setWishes(JSON.parse(raw) as Wish[]);
      }
    } catch {
      /* ignore */
    }
    return () => {
      document.body.classList.remove("invite-locked");
      document.body.style.overflow = "";
    };
  }, []);

  useEffect(() => {
    setWishName(guestName === "Tamu Undangan" ? "" : guestName);
  }, [guestName]);

  useEffect(() => {
    const tick = () => {
      let diff = WEDDING_TARGET - Date.now();
      if (diff < 0) diff = 0;
      setCd({
        d: pad(Math.floor(diff / (1000 * 60 * 60 * 24))),
        h: pad(Math.floor((diff / (1000 * 60 * 60)) % 24)),
        m: pad(Math.floor((diff / (1000 * 60)) % 60)),
        s: pad(Math.floor((diff / 1000) % 60)),
      });
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  const calendarHref = useMemo(() => {
    const text = encodeURIComponent("The Wedding of Liya & Lukman");
    const details = encodeURIComponent(
      "Pernikahan Miinatul Mauliyati Zahroh & Lukman Hakim di Rumah Makan Dapur Kawalli"
    );
    const location = encodeURIComponent("Rumah Makan Dapur Kawalli");
    return `https://www.google.com/calendar/render?action=TEMPLATE&text=${text}&details=${details}&location=${location}&dates=20260906T010000Z/20260906T060000Z`;
  }, []);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2200);
  };

  const toggleMusic = () => {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().then(() => setIsPlaying(true)).catch(() => { });
    }
  };

  const openInvite = () => {
    setOpened(true);
    document.body.classList.remove("invite-locked");
    document.body.style.overflow = "auto";
    if (audioRef.current) {
      audioRef.current
        .play()
        .then(() => setIsPlaying(true))
        .catch(() => { });
    }
  };

  const copyText = (id: string, value: string, label: string) => {
    navigator.clipboard.writeText(value).then(() => {
      setCopiedId(id);
      showToast(`${label} Tersalin`);
      setTimeout(() => setCopiedId(null), 1800);
    });
  };

  const submitWish = (e: FormEvent) => {
    e.preventDefault();
    const name = wishName.trim();
    const message = wishMessage.trim();
    if (name.length < 2 || message.length < 2) {
      showToast("Minimal 2 karakter");
      return;
    }
    const next = [{ name, message, at: Date.now() }, ...wishes].slice(0, 50);
    setWishes(next);
    localStorage.setItem(WISHES_KEY, JSON.stringify(next));
    setWishMessage("");
    showToast("Terima kasih atas doa & ucapannya");
  };

  const galleryImages = [
    {
      src: "/wedding/REY05710-2-Lukman-Hakim-768x1152.jpg",
      wide: true,
      alt: "Liya & Lukman",
      position: "center 65%",
    },
    { src: "/wedding/gal-a.jpg", wide: false, alt: "Liya & Lukman" },
    { src: "/wedding/gal-b.jpg", wide: false, alt: "Liya & Lukman" },
    { src: "/wedding/gal-c.jpg", wide: false, alt: "Liya & Lukman" },
    { src: "/wedding/gal-d.jpg", wide: false, alt: "Liya & Lukman" },
    {
      src: "/wedding/REY05690-2.jpg",
      wide: true,
      alt: "Liya & Lukman",
      position: "center 50%",
    },
  ];

  return (
    <div className={styles.app}>
      {/* Hidden Audio */}
      <audio
        ref={audioRef}
        src="/music/Westlife - Nothing's Going to Change My Love For You.mp3"
        loop
        preload="auto"
      />

      {/* Floating Music Button */}
      {opened && (
        <button
          type="button"
          className={`${styles.musicBtn} ${isPlaying ? styles.musicSpin : ""}`}
          onClick={toggleMusic}
          aria-label={isPlaying ? "Pause Music" : "Play Music"}
          title={isPlaying ? "Jeda Musik" : "Putar Musik"}
        >
          {isPlaying ? (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
            </svg>
          ) : (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M4.27 3L3 4.27l9 9v.28c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4v-1.73l4 4V19h4v-3.73l2.73 2.73 1.27-1.27L4.27 3zM14 7h4V3h-6v5.18l2 2V7z" />
            </svg>
          )}
        </button>
      )}

      {/* COVER OVERLAY (Matching reference screenshot exactly) */}
      <div className={`${styles.cover}${opened ? ` ${styles.opened}` : ""}`}>
        <div className={styles.coverEyebrow}>THE WEDDING OF</div>
        <div className={styles.coverNames}>Liya &amp; Lukman</div>
        <div className={styles.coverDate}>6 September 2026</div>

        <div className={styles.guestBox}>
          <div className={styles.label}>KPD BPK/IBU/SAUDARA/I</div>
          <div className={styles.name}>{guestName}</div>
        </div>

        <button type="button" className={styles.btn} onClick={openInvite}>
          BUKA UNDANGAN
        </button>
      </div>

      {/* MAIN INVITATION CONTENT */}
      <main>
        {/* OPENING SECTION */}
        <section className={`${styles.section} ${styles.opening} ${styles.center}`}>
          <div className={styles.openingTitle}>Our Wedding Invitation</div>
          <div className={styles.openingNames}>Liya &amp; Lukman</div>
          <p className={styles.openingQuote}>
            &ldquo;What counts in making a happy marriage is not so much how
            compatible you are, but how you deal with incompatibility. A great
            marriage is not when the perfect couple comes together. It is when an
            imperfect couple learns to enjoy their differences.&rdquo;
          </p>
          <div className={styles.eyebrow}>Kepada Yth. Bapak / Ibu / Saudara/i</div>
          <div
            className={styles.serif}
            style={{ fontSize: "1.4rem", marginTop: 10, color: "var(--cream)" }}
          >
            {guestName}
          </div>
        </section>

        {/* BRIDE & GROOM */}
        <section className={`${styles.section} ${styles.couple}`}>
          <div className={styles.kicker}>
            <span className={styles.eyebrow}>Bride &amp; Groom</span>
            <h2 className={styles.serif} style={{ fontSize: "1.6rem" }}>
              The Wedding of
            </h2>
            <div
              className={styles.serif}
              style={{ fontSize: "1.8rem", marginTop: 6 }}
            >
              Liya &amp; Lukman
            </div>
            <div className={styles.coverDate} style={{ marginTop: 8 }}>
              Minggu, 6 September 2026
            </div>
          </div>
          <p className={styles.bodyText} style={{ marginBottom: 28 }}>
            Tanpa mengurangi rasa hormat, kami bermaksud mengundang
            Bapak/Ibu/Saudara/i untuk menghadiri acara pernikahan anak kami:
          </p>

          <div className={styles.pair}>
            {/* BRIDE */}
            <div className={styles.profile}>
              <div className={styles.portraitWrap}>
                <Image
                  src="/wedding/liya-01.jpg"
                  alt="Miinatul Mauliyati Zahroh"
                  width={200}
                  height={260}
                  priority
                />
              </div>
              <div className={styles.nick}>liya</div>
              <div className={styles.fullName}>
                Miinatul Mauliyati Zahroh, S.K.M
              </div>
              <div className={styles.parents}>
                Putri dari
                <br />
                <strong>Bapak H. Mafadil &amp; Ibu Hj. Siti Nurfaidah</strong>
              </div>
            </div>

            <div className={styles.amp}>&amp;</div>

            {/* GROOM */}
            <div className={styles.profile}>
              <div className={styles.portraitWrap}>
                <Image
                  src="/wedding/lukman-01.jpg"
                  alt="Lukman Hakim"
                  width={200}
                  height={260}
                  priority
                />
              </div>
              <div className={styles.nick}>Lukman</div>
              <div className={styles.fullName}>Lukman Hakim, S.Mat</div>
              <div className={styles.parents}>
                Putra dari
                <br />
                <strong>Bapak Hasyim &amp; Ibu Umaiyah</strong>
              </div>
            </div>
          </div>
        </section>

        {/* COUNTDOWN */}
        <section className={`${styles.section} ${styles.countdown} ${styles.center}`}>
          <span className={styles.eyebrow}>Count The Date</span>
          <div className={styles.divider} />
          <div className={styles.cdGrid}>
            <div className={styles.cdItem}>
              <div className={styles.cdNum}>{cd.d}</div>
              <div className={styles.cdLbl}>Hari</div>
            </div>
            <div className={styles.cdItem}>
              <div className={styles.cdNum}>{cd.h}</div>
              <div className={styles.cdLbl}>Jam</div>
            </div>
            <div className={styles.cdItem}>
              <div className={styles.cdNum}>{cd.m}</div>
              <div className={styles.cdLbl}>Menit</div>
            </div>
            <div className={styles.cdItem}>
              <div className={styles.cdNum}>{cd.s}</div>
              <div className={styles.cdLbl}>Detik</div>
            </div>
          </div>
          <a
            className={`${styles.btn} ${styles.btnOutline}`}
            href={calendarHref}
            target="_blank"
            rel="noopener noreferrer"
          >
            Simpan di Kalender
          </a>
        </section>

        {/* VERSE QUOTE */}
        <section className={`${styles.section} ${styles.quote} ${styles.center}`}>
          <p className={styles.quoteText}>
            &ldquo;Dan di antara tanda-tanda kekuasaan-Nya diciptakan-Nya untukmu
            pasangan hidup dari jenismu sendiri supaya kamu dapat ketenangan hati
            dan dijadikannya kasih sayang di antara kamu. Sesungguhnya yang
            demikian menjadi tanda-tanda kebesaran-Nya bagi orang-orang yang
            berpikir.&rdquo;
          </p>
          <div className={styles.cite}>( QS. Ar - Rum 21 )</div>
        </section>

        {/* EVENTS */}
        <section className={`${styles.section} ${styles.events} ${styles.center}`}>
          <div className={styles.kicker}>
            <span className={styles.eyebrow}>Wedding Event</span>
          </div>

          <div className={styles.eventCard}>
            <div className={styles.tag}>Resepsi</div>
            <div className={styles.day}>Minggu, 6 September 2026</div>
            <div className={styles.time}>Pukul : 16.00-21.00</div>
            <div className={styles.venue}>
              <strong>Kediaman Mempelai Wanita</strong>
              Jl. M. Siban Gg Purwasari II No 172, RT.002/RW.008, Kunciran Indah, Kec. Pinang, Kota Tangerang, Banten 15144
            </div>
            <a
              className={`${styles.btn} ${styles.btnOutline}`}
              href={MAPS_URL_RESEPSI}
              target="_blank"
              rel="noopener noreferrer"
            >
              Lihat Lokasi
            </a>
          </div>
        </section>

        {/* GALLERY */}
        <section className={`${styles.section} ${styles.gallery}`}>
          <div className={styles.kicker}>
            <span className={styles.eyebrow}>Wedding Gallery</span>
          </div>
          <div className={styles.galGrid}>
            {galleryImages.map((img, idx) => (
              <div
                key={idx}
                className={`${styles.galItem} ${img.wide ? styles.wide : ""}`}
                onClick={() => setLightboxImg(img.src)}
              >
                <Image
                  src={img.src}
                  alt={img.alt}
                  width={img.wide ? 480 : 240}
                  height={img.wide ? 280 : 220}
                  style={img.position ? { objectPosition: img.position } : undefined}
                  loading="lazy"
                />
              </div>
            ))}
          </div>
        </section>

        {/* LIGHTBOX MODAL */}
        {lightboxImg && (
          <div className={styles.lightbox} onClick={() => setLightboxImg(null)}>
            <div
              className={styles.lightboxContent}
              onClick={(e) => e.stopPropagation()}
            >
              <Image
                src={lightboxImg}
                alt="Liya & Lukman"
                width={800}
                height={600}
              />
              <button
                type="button"
                className={styles.lightboxClose}
                onClick={() => setLightboxImg(null)}
              >
                ✕
              </button>
            </div>
          </div>
        )}

        {/* WEDDING GIFT */}
        <section className={`${styles.section} ${styles.gift} ${styles.center}`}>
          <span className={styles.eyebrow}>Wedding Gift</span>
          <div className={styles.divider} />
          <p className={styles.bodyText} style={{ marginBottom: 24 }}>
            Doa Restu Anda merupakan karunia yang sangat berarti bagi kami. Namun
            jika memberi adalah ungkapan tanda kasih Anda, Anda dapat memberi gift:
          </p>

          <div className={styles.bankCard}>
            <div className={styles.bankName}>Bank BCA — {BANK_NAME_LUKMAN}</div>
            <div className={styles.acc}>{BANK_ACC}</div>
            <button
              type="button"
              className={`${styles.copyBtn}${copiedId === "bank" ? ` ${styles.copied}` : ""
                }`}
              onClick={() => copyText("bank", BANK_ACC, "No Rekening")}
            >
              {copiedId === "bank" ? "Tersalin" : "Salin No Rekening"}
            </button>
          </div>

          <div className={styles.addressCard}>
            <div className={styles.addressTitle}>GIFT FISIK</div>
            <div className={styles.addressText}>Alamat : {GIFT_ADDRESS}</div>
            <button
              type="button"
              className={`${styles.copyBtn}${copiedId === "addr" ? ` ${styles.copied}` : ""
                }`}
              onClick={() => copyText("addr", GIFT_ADDRESS, "Alamat")}
            >
              {copiedId === "addr" ? "Tersalin" : "Salin Alamat"}
            </button>
          </div>
        </section>

        {/* WISHES */}
        <section className={`${styles.section} ${styles.wishes} ${styles.center}`}>
          <span className={styles.eyebrow}>Doa &amp; Ucapan</span>
          <div className={styles.divider} />
          <p className={styles.wishCount}>
            {wishes.length} Ucapan
          </p>
          <form className={styles.wishForm} onSubmit={submitWish}>
            <input
              className={styles.wishInput}
              value={wishName}
              onChange={(e) => setWishName(e.target.value)}
              placeholder="Nama"
              required
              minLength={2}
            />
            <textarea
              className={styles.wishTextarea}
              value={wishMessage}
              onChange={(e) => setWishMessage(e.target.value)}
              placeholder="Doa & ucapan"
              required
              minLength={2}
            />
            <p className={styles.wishHint}>
              *Mohon maaf! Khusus untuk tamu undangan
              <br />
              *Minimal 2 karakter.
            </p>
            <button type="submit" className={styles.btn}>
              Kirim Ucapan
            </button>
          </form>
          {wishes.length > 0 && (
            <div className={styles.wishList}>
              {wishes.map((w, idx) => (
                <div key={idx} className={styles.wishItem}>
                  <div className={styles.wishAuthor}>{w.name}</div>
                  <div className={styles.wishMessage}>{w.message}</div>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* RSVP */}
        <section className={`${styles.section} ${styles.rsvp} ${styles.center}`}>
          <span className={styles.eyebrow}>Konfirmasi Kehadiran</span>
          <div className={styles.divider} />
          <p className={styles.bodyText}>Silahkan pilih konfirmasi kehadiran</p>
          <div className={styles.rsvpChoice}>
            <button
              type="button"
              className={`${styles.rsvpBtn} ${rsvpStatus === "yes" ? styles.active : ""}`}
              onClick={() => {
                setRsvpStatus("yes");
                showToast("Terima kasih, konfirmasi: Hadir");
              }}
            >
              Hadir
            </button>
            <button
              type="button"
              className={`${styles.rsvpBtn} ${rsvpStatus === "no" ? styles.active : ""}`}
              onClick={() => {
                setRsvpStatus("no");
                showToast("Terima kasih, konfirmasi: Tidak Hadir");
              }}
            >
              Tidak Hadir
            </button>
          </div>
        </section>

        {/* CLOSING */}
        <section className={`${styles.section} ${styles.closing}`}>
          <div className={styles.thanks}>Thank You</div>
          <div className={styles.closingNames}>Liya &amp; Lukman</div>
          <div className={styles.credit}>6 September 2026</div>
        </section>
      </main>

      {/* TOAST */}
      {toast && <div className={styles.toast}>{toast}</div>}
    </div>
  );
}

export default function Home() {
  return (
    <Suspense
      fallback={
        <div
          style={{
            background: "#141414",
            minHeight: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#dac0a3",
            fontFamily: "var(--font-playfair), serif",
          }}
        >
          Memuat Undangan...
        </div>
      }
    >
      <WeddingInvitation />
    </Suspense>
  );
}
