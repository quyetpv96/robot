import os
import cv2
import traceback
import pytesseract
import numpy as np
import unicodedata

from pytesseract import Output
from robot.api.deco import keyword

try:
    from rapidfuzz import fuzz
    USE_RAPIDFUZZ = True
except ImportError:
    from difflib import SequenceMatcher
    USE_RAPIDFUZZ = False


class ImageCompare:
    def __init__(self):
        self.tesseract_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

    # =========================
    # TEXT NORMALIZE
    # =========================
    def _normalize_text(self, text):
        text = text.lower()
        text = unicodedata.normalize('NFKD', text)
        text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
        return text.strip()

    def _similar(self, a, b):
        a = self._normalize_text(a)
        b = self._normalize_text(b)

        if USE_RAPIDFUZZ:
            return fuzz.partial_ratio(a, b) / 100.0
        else:
            return SequenceMatcher(None, a, b).ratio()

    # =========================
    # PREPROCESS IMAGE
    # =========================
    def _preprocess_for_ocr(self, img):
        # upscale để OCR tốt hơn
        img = cv2.resize(img, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray = clahe.apply(gray)

        thresh = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            31, 2
        )

        return thresh

    # =========================
    # OCR FULL IMAGE
    # =========================
    @keyword("Convert IMG to String")
    def ocr(self, img_path, language='vie+eng'):
        pytesseract.pytesseract.tesseract_cmd = self.tesseract_path
        try:
            img = cv2.imread(img_path)
            if img is None:
                return ''

            proc = self._preprocess_for_ocr(img)

            text = pytesseract.image_to_string(
                proc,
                lang=language,
                config='--psm 6'
            )

            return text.replace('\n', ' ').strip()

        except Exception:
            traceback.print_exc()
            return ''

    # =========================
    # FIND STRING (MAIN)
    # =========================
    @keyword("Find string on screen")
    def find_string_on_screen(
        self,
        img_path,
        target_string,
        lang='vie+eng',
        threshold=0.6,
        debug=False
    ):
        pytesseract.pytesseract.tesseract_cmd = self.tesseract_path

        try:
            img = cv2.imread(img_path)
            if img is None:
                return 'fail', -1, -1

            proc = self._preprocess_for_ocr(img)

            data = pytesseract.image_to_data(
                proc,
                lang=lang,
                config='--psm 6',
                output_type=Output.DICT
            )

            n = len(data['text'])

            # ===== Gom theo line =====
            lines = {}
            for i in range(n):
                text = data['text'][i].strip()
                if not text:
                    continue

                line_id = (
                    data['block_num'][i],
                    data['par_num'][i],
                    data['line_num'][i]
                )

                if line_id not in lines:
                    lines[line_id] = {
                        "words": [],
                        "indices": []
                    }

                lines[line_id]["words"].append(text)
                lines[line_id]["indices"].append(i)

            best_score = 0
            best_indices = []

            target_words_len = len(target_string.split())

            # ===== Sliding window matching =====
            for line_id, content in lines.items():
                words = content["words"]
                indices = content["indices"]

                for i in range(len(words)):
                    for j in range(i + 1, min(i + target_words_len + 4, len(words))):
                        phrase = " ".join(words[i:j])
                        score = self._similar(target_string, phrase)

                        if score > best_score:
                            best_score = score
                            best_indices = indices[i:j]

            print("BEST SCORE:", best_score)

            if best_score >= threshold and best_indices:
                xs, ys, xe, ye = [], [], [], []

                for idx in best_indices:
                    x = data['left'][idx]
                    y = data['top'][idx]
                    w = data['width'][idx]
                    h = data['height'][idx]

                    xs.append(x)
                    ys.append(y)
                    xe.append(x + w)
                    ye.append(y + h)

                x1, y1 = min(xs), min(ys)
                x2, y2 = max(xe), max(ye)

                cx = (x1 + x2) // 2
                cy = (y1 + y2) // 2

                if debug:
                    debug_img = img.copy()
                    cv2.rectangle(debug_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(debug_img, f"{best_score:.2f}", (x1, y1 - 5),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                    cv2.imwrite("midou_checking.png", debug_img)

                return 'pass', int(cx), int(cy)

            return 'fail', -1, -1

        except Exception:
            traceback.print_exc()
            return 'fail', -1, -1

    @keyword("Find image on screen")
    def find_image_on_screen(
            self,
            screen_path,
            template_path,
            threshold=0.8,
            debug=False
    ):
        try:
            screen = cv2.imread(screen_path)
            template = cv2.imread(template_path)

            if screen is None or template is None:
                return 'fail', -1, -1

            # Convert grayscale
            screen_gray = cv2.cvtColor(screen, cv2.COLOR_BGR2GRAY)
            template_gray = cv2.cvtColor(template, cv2.COLOR_BGR2GRAY)

            h, w = template_gray.shape

            # Template matching
            result = cv2.matchTemplate(screen_gray, template_gray, cv2.TM_CCOEFF_NORMED)

            min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

            print("MATCH SCORE:", max_val)

            if max_val >= threshold:
                top_left = max_loc
                bottom_right = (top_left[0] + w, top_left[1] + h)

                cx = top_left[0] + w // 2
                cy = top_left[1] + h // 2

                if debug:
                    debug_img = screen.copy()
                    cv2.rectangle(debug_img, top_left, bottom_right, (0, 255, 0), 2)
                    cv2.putText(debug_img, f"{max_val:.2f}",
                                (top_left[0], top_left[1] - 5),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.7,
                                (0, 255, 0),
                                2)

                    cv2.imwrite("debug_template_match.png", debug_img)

                return 'pass', int(cx), int(cy)

            return 'fail', -1, -1

        except Exception:
            traceback.print_exc()
            return 'fail', -1, -1

# =========================
# TEST
# =========================
if __name__ == '__main__':
    im = ImageCompare()

    print("===== OCR =====")
    text = im.ocr('E:\\a.png')
    print(text)

    print("\n===== FIND =====")
    result, x, y = im.find_string_on_screen(
        'E:\\a.png',
        'pewpew',
        threshold=0.9,
        debug=True
    )

    print("Result:", result, x, y)