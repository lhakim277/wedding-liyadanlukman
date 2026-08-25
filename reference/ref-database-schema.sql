-- ==============================================================================
-- DATABASE SCHEMA: WEDDING INVITATION (SUPABASE / POSTGRESQL)
-- Website: The Wedding of Liya & Lukman (Miinatul & Lukman)
-- Target Date: 6 September 2026
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. TABEL: guests (Data Tamu Undangan & Personalisasi URL)
-- ==============================================================================
-- Menyimpan daftar tamu yang diundang, kode unik slug untuk URL (?to=slug/nama),
-- nomor WhatsApp untuk broadcast, dan tracking apakah undangan sudah dibuka.
CREATE TABLE IF NOT EXISTS public.guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(30),
    category VARCHAR(100) DEFAULT 'Reguler', -- Contoh: 'Keluarga', 'Sahabat', 'VIP', 'Rekan Kerja'
    pax_allocated INT NOT NULL DEFAULT 1 CHECK (pax_allocated > 0),
    is_opened BOOLEAN NOT NULL DEFAULT false,
    opened_at TIMESTAMPTZ,
    open_count INT NOT NULL DEFAULT 0,
    custom_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index untuk mempercepat pencarian tamu via slug/URL
CREATE INDEX IF NOT EXISTS idx_guests_slug ON public.guests(slug);
CREATE INDEX IF NOT EXISTS idx_guests_category ON public.guests(category);

COMMENT ON TABLE public.guests IS 'Menyimpan data master tamu undangan serta status interaksi URL personal';
COMMENT ON COLUMN public.guests.slug IS 'Identifier unik untuk URL personal, contoh: ?to=bapak-ahmad';
COMMENT ON COLUMN public.guests.is_opened IS 'Menandakan apakah tamu sudah pernah membuka undangan';


-- ==============================================================================
-- 2. TABEL: rsvps (Konfirmasi Kehadiran Tamu)
-- ==============================================================================
-- Menyimpan data konfirmasi kehadiran dari tamu (Hadir / Tidak Hadir / Ragu-ragu),
-- jumlah orang yang hadir, serta terhubung dengan tabel guests.
CREATE TABLE IF NOT EXISTS public.rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES public.guests(id) ON DELETE SET NULL,
    guest_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('attending', 'not_attending', 'tentative')),
    pax_attending INT NOT NULL DEFAULT 1 CHECK (pax_attending >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index untuk query status kehadiran dan relasi tamu
CREATE INDEX IF NOT EXISTS idx_rsvps_guest_id ON public.rsvps(guest_id);
CREATE INDEX IF NOT EXISTS idx_rsvps_status ON public.rsvps(status);
CREATE INDEX IF NOT EXISTS idx_rsvps_created_at ON public.rsvps(created_at DESC);

COMMENT ON TABLE public.rsvps IS 'Menyimpan data konfirmasi RSVP kehadiran tamu undangan';


-- ==============================================================================
-- 3. TABEL: wishes (Buku Tamu / Doa & Ucapan)
-- ==============================================================================
-- Menyimpan doa dan ucapan selamat dari tamu, status visibilitas/moderasi,
-- dan fitur pin untuk ucapan spesial.
CREATE TABLE IF NOT EXISTS public.wishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES public.guests(id) ON DELETE SET NULL,
    sender_name VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_visible BOOLEAN NOT NULL DEFAULT true,
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    likes_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index untuk sorting ucapan terbaru dan filter visibilitas
CREATE INDEX IF NOT EXISTS idx_wishes_created_at ON public.wishes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wishes_visibility ON public.wishes(is_visible, is_pinned);

COMMENT ON TABLE public.wishes IS 'Menyimpan ucapan doa restu dari para tamu undangan';


-- ==============================================================================
-- 4. TABEL: gallery_items (Galeri Foto & Dokumentasi)
-- ==============================================================================
-- Menyimpan daftar foto pernikahan/prewedding secara dinamis dari Supabase Storage
-- atau CDN eksternal lengkap dengan urutan tampilan dan layout wide/grid.
CREATE TABLE IF NOT EXISTS public.gallery_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255),
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    alt_text VARCHAR(255) DEFAULT 'Foto Pernikahan Liya & Lukman',
    aspect_ratio VARCHAR(20) DEFAULT 'square' CHECK (aspect_ratio IN ('square', 'landscape', 'portrait', 'wide')),
    is_wide BOOLEAN NOT NULL DEFAULT false,
    object_position VARCHAR(50) DEFAULT 'center 50%',
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gallery_sort ON public.gallery_items(is_active, sort_order ASC);

COMMENT ON TABLE public.gallery_items IS 'Daftar koleksi foto prewedding/wedding untuk galeri interaktif';


-- ==============================================================================
-- 5. TABEL: wedding_events (Rangkaian Acara Pernikahan)
-- ==============================================================================
-- Menyimpan detail jadwal acara (Akad Nikah, Resepsi, dll), lokasi, alamat,
-- serta tautan Google Maps & Google Calendar.
CREATE TABLE IF NOT EXISTS public.wedding_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_tag VARCHAR(100) NOT NULL, -- Contoh: 'Akad Nikah', 'Resepsi'
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    timezone VARCHAR(10) NOT NULL DEFAULT 'WIB',
    venue_name VARCHAR(255) NOT NULL,
    venue_address TEXT NOT NULL,
    maps_url TEXT NOT NULL,
    calendar_url TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_events_sort ON public.wedding_events(is_active, sort_order ASC);

COMMENT ON TABLE public.wedding_events IS 'Detail rangkaian acara pernikahan seperti Akad dan Resepsi';


-- ==============================================================================
-- 6. TABEL: gift_accounts (Rekening Amplop Digital & Kado Fisik)
-- ==============================================================================
-- Menyimpan informasi rekening bank, e-wallet, atau alamat pengiriman kado fisik.
CREATE TABLE IF NOT EXISTS public.gift_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(30) NOT NULL CHECK (type IN ('bank', 'ewallet', 'physical_address')),
    provider_name VARCHAR(100) NOT NULL, -- Contoh: 'Bank BCA', 'Bank BRI', 'Alamat Kirim Kado'
    account_number TEXT NOT NULL, -- Nomor rekening atau alamat lengkap
    account_holder VARCHAR(255) NOT NULL, -- Contoh: 'Lukman Hakim' / 'Siti Nurfaidah'
    qr_code_url TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gifts_sort ON public.gift_accounts(is_active, sort_order ASC);

COMMENT ON TABLE public.gift_accounts IS 'Informasi rekening bank dan alamat pengiriman kado pernikahan';


-- ==============================================================================
-- 7. TABEL: wedding_settings (Pengaturan & Profil Mempelai)
-- ==============================================================================
-- Menyimpan konten dinamis website seperti nama mempelai, kutipan, foto profil,
-- waktu hitung mundur, dan link lagu latar.
CREATE TABLE IF NOT EXISTS public.wedding_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_title VARCHAR(255) NOT NULL DEFAULT 'Liya & Lukman',
    wedding_date_text VARCHAR(100) NOT NULL DEFAULT 'Minggu, 6 September 2026',
    wedding_target_timestamp TIMESTAMPTZ NOT NULL DEFAULT '2026-09-06 08:00:00+07',
    
    -- Profil Mempelai Wanita
    bride_full_name VARCHAR(255) NOT NULL DEFAULT 'Miinatul Mauliyati Zahroh, S.K.M',
    bride_nickname VARCHAR(100) NOT NULL DEFAULT 'liya',
    bride_parents TEXT NOT NULL DEFAULT 'Bapak H. Mafadil & Ibu Hj. Siti Nurfaidah',
    bride_photo_url TEXT DEFAULT '/wedding/portrait-bride.jpg',
    
    -- Profil Mempelai Pria
    groom_full_name VARCHAR(255) NOT NULL DEFAULT 'Lukman Hakim, S.Mat',
    groom_nickname VARCHAR(100) NOT NULL DEFAULT 'Lukman',
    groom_parents TEXT NOT NULL DEFAULT 'Bapak Hasyim & Ibu Umaiyah',
    groom_photo_url TEXT DEFAULT '/wedding/portrait-groom.jpg',
    
    -- Asset & Teks Kutipan
    cover_photo_url TEXT DEFAULT '/wedding/cover-ref.jpg',
    music_url TEXT DEFAULT '/music/Westlife - Nothing''s Going to Change My Love For You.mp3',
    opening_quote TEXT,
    verse_quote TEXT,
    verse_source VARCHAR(100) DEFAULT 'QS. Ar - Rum 21',
    
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.wedding_settings IS 'Data pengaturan global, profil mempelai, dan kutipan website';


-- ==============================================================================
-- 8. VIEW: v_rsvp_summary (Ringkasan Kehadiran Realtime)
-- ==============================================================================
CREATE OR REPLACE VIEW public.v_rsvp_summary AS
SELECT
    COUNT(*) AS total_rsvp_submissions,
    COUNT(*) FILTER (WHERE status = 'attending') AS total_attending_responses,
    COUNT(*) FILTER (WHERE status = 'not_attending') AS total_not_attending_responses,
    COUNT(*) FILTER (WHERE status = 'tentative') AS total_tentative_responses,
    COALESCE(SUM(pax_attending) FILTER (WHERE status = 'attending'), 0) AS total_estimated_guests_attending
FROM public.rsvps;


-- ==============================================================================
-- 9. STORED PROCEDURE / FUNCTION: increment_guest_open_count
-- ==============================================================================
-- Fungsi untuk mencatat secara atomik saat tamu membuka undangan melalui URL personal
CREATE OR REPLACE FUNCTION public.track_guest_open(p_slug TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE public.guests
    SET 
        is_opened = true,
        opened_at = COALESCE(opened_at, now()),
        open_count = open_count + 1,
        updated_at = now()
    WHERE slug = p_slug;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
-- Mengamankan akses data di Supabase untuk pengguna publik (Anon) dan Admin.

-- Aktifkan RLS di semua tabel
ALTER TABLE public.guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_settings ENABLE ROW LEVEL SECURITY;

-- 10.1 Policies untuk Tabel guests
CREATE POLICY "Public can read own guest data by slug" 
ON public.guests FOR SELECT TO anon, authenticated 
USING (true);

-- 10.2 Policies untuk Tabel rsvps
CREATE POLICY "Public can view RSVPs" 
ON public.rsvps FOR SELECT TO anon, authenticated 
USING (true);

CREATE POLICY "Public can submit RSVP" 
ON public.rsvps FOR INSERT TO anon, authenticated 
WITH CHECK (true);

-- 10.3 Policies untuk Tabel wishes
CREATE POLICY "Public can view visible wishes" 
ON public.wishes FOR SELECT TO anon, authenticated 
USING (is_visible = true);

CREATE POLICY "Public can post wishes" 
ON public.wishes FOR INSERT TO anon, authenticated 
WITH CHECK (true);

-- 10.4 Policies untuk Tabel Read-Only Publik (Galeri, Events, Gifts, Settings)
CREATE POLICY "Public can view active gallery items" 
ON public.gallery_items FOR SELECT TO anon, authenticated 
USING (is_active = true);

CREATE POLICY "Public can view active wedding events" 
ON public.wedding_events FOR SELECT TO anon, authenticated 
USING (is_active = true);

CREATE POLICY "Public can view active gift accounts" 
ON public.gift_accounts FOR SELECT TO anon, authenticated 
USING (is_active = true);

CREATE POLICY "Public can view wedding settings" 
ON public.wedding_settings FOR SELECT TO anon, authenticated 
USING (true);

-- ==============================================================================
-- 11. DUMMY DATA SEEDING (Data Awal Sesuai Website Saat Ini)
-- ==============================================================================

-- Seed Settings
INSERT INTO public.wedding_settings (
    couple_title,
    wedding_date_text,
    wedding_target_timestamp,
    bride_full_name,
    bride_nickname,
    bride_parents,
    groom_full_name,
    groom_nickname,
    groom_parents,
    cover_photo_url,
    opening_quote,
    verse_quote,
    verse_source
) VALUES (
    'Liya & Lukman',
    'Minggu, 6 September 2026',
    '2026-09-06 08:00:00+07',
    'Miinatul Mauliyati Zahroh, S.K.M',
    'liya',
    'Bapak H. Mafadil & Ibu Hj. Siti Nurfaidah',
    'Lukman Hakim, S.Mat',
    'Lukman',
    'Bapak Hasyim & Ibu Umaiyah',
    '/wedding/cover-ref.jpg',
    'What counts in making a happy marriage is not so much how compatible you are, but how you deal with incompatibility. A great marriage is not when the perfect couple comes together. It is when an imperfect couple learns to enjoy their differences.',
    'Dan di antara tanda-tanda kekuasaan-Nya diciptakan-Nya untukmu pasangan hidup dari jenismu sendiri supaya kamu dapat ketenangan hati dan dijadikannya kasih sayang di antara kamu. Sesungguhnya yang demikian menjadi tanda-tanda kebesaran-Nya bagi orang-orang yang berpikir.',
    'QS. Ar - Rum 21'
) ON CONFLICT DO NOTHING;

-- Seed Wedding Events (Resepsi)
INSERT INTO public.wedding_events (
    event_tag,
    event_date,
    start_time,
    end_time,
    venue_name,
    venue_address,
    maps_url,
    sort_order
) VALUES (
    'Resepsi',
    '2026-09-06',
    '16:00:00',
    '21:00:00',
    'Kediaman Mempelai Wanita',
    'Jl. M. Siban Gg Purwasari II No 172, RT.002/RW.008, Kunciran Indah, Kec. Pinang, Kota Tangerang, Banten 15144',
    'https://maps.app.goo.gl/dUms5Z9cxpoVXWvk7',
    1
) ON CONFLICT DO NOTHING;

-- Seed Gift Accounts
INSERT INTO public.gift_accounts (type, provider_name, account_number, account_holder, sort_order)
VALUES 
('bank', 'Bank BCA', '7645012976', 'Lukman Hakim', 1),
('physical_address', 'KIRIM KADO FISIK', 'Jl. M. Siban Bojong Poncol No.172, RT.002/RW.008, Kunciran Indah, Kec. Pinang, Kota Tangerang, Banten 15144', 'Penerima: Liya & Lukman', 2)
ON CONFLICT DO NOTHING;

-- Seed Sample Gallery Items
INSERT INTO public.gallery_items (title, image_url, is_wide, object_position, sort_order)
VALUES 
('Prewedding 1', '/wedding/REY05710-2-Lukman-Hakim-768x1152.jpg', true, 'center 65%', 1),
('Prewedding 2', '/wedding/gal-a.jpg', false, 'center 50%', 2),
('Prewedding 3', '/wedding/gal-b.jpg', false, 'center 50%', 3),
('Prewedding 4', '/wedding/gal-c.jpg', false, 'center 50%', 4),
('Prewedding 5', '/wedding/gal-d.jpg', false, 'center 50%', 5),
('Prewedding 6', '/wedding/REY05690-2.jpg', true, 'center 50%', 6)
ON CONFLICT DO NOTHING;
