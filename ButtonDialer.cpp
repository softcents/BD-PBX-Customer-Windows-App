/*
 * Copyright (C) 2011-2024 MicroSIP (http://www.microsip.org)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "stdafx.h"
#include "ButtonDialer.h"
#include "Strsafe.h"
#include "const.h"

/////////////////////////////////////////////////////////////////////////////
// CButtonDialer

CButtonDialer::CButtonDialer()
{
	forceNumeric = false;
	m_map.SetAt(_T("1"), _T(""));
	m_map.SetAt(_T("2"), _T("ABC"));
	m_map.SetAt(_T("3"), _T("DEF"));
	m_map.SetAt(_T("4"), _T("GHI"));
	m_map.SetAt(_T("5"), _T("JKL"));
	m_map.SetAt(_T("6"), _T("MNO"));
	m_map.SetAt(_T("7"), _T("PQRS"));
	m_map.SetAt(_T("8"), _T("TUV"));
	m_map.SetAt(_T("9"), _T("WXYZ"));
	m_map.SetAt(_T("0"), _T(""));
	m_map.SetAt(_T("*"), _T(""));
	m_map.SetAt(_T("#"), _T(""));
}

CButtonDialer::~CButtonDialer()
{
	CloseTheme();
}


BEGIN_MESSAGE_MAP(CButtonDialer, CButton)
	ON_WM_THEMECHANGED()
	ON_WM_MOUSEMOVE()
	ON_WM_SIZE()
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CButtonDialer message handlers

void CButtonDialer::PreSubclassWindow()
{
	OpenTheme();

	HFONT hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
	LOGFONT lf;
	GetObject(hFont, sizeof(LOGFONT), &lf);
	lf.lfHeight = 12;
	CDC *pDC = GetDC();
	if (pDC) {
		dpiY = GetDeviceCaps(pDC->m_hDC, LOGPIXELSY);
		lf.lfHeight = MulDiv(lf.lfHeight, dpiY, 96);
		ReleaseDC(pDC);
	}
	else {
		dpiY = 96;
	}
	StringCchCopy(lf.lfFaceName, LF_FACESIZE, _T("Microsoft Sans Serif"));
	m_FontLetters.CreateFontIndirect(&lf);

	DWORD dwStyle = ::GetClassLong(m_hWnd, GCL_STYLE);
	dwStyle &= ~CS_DBLCLKS;
	::SetClassLong(m_hWnd, GCL_STYLE, dwStyle);
}

LRESULT CButtonDialer::OnThemeChanged()
{
	CloseTheme();
	OpenTheme();
	return 0L;
}

void CButtonDialer::OnSize(UINT type, int w, int h)
{
	CButton::OnSize(type, w, h);
}

void CButtonDialer::OnMouseMove(UINT nFlags, CPoint point)
{
	CRect rect;
	GetClientRect(&rect);
	if (rect.PtInRect(point)) {
		if (GetCapture() != this) {
			SetCapture();
			Invalidate();
		}
	}
	else {
		ReleaseCapture();
		Invalidate();
	}
}

void CButtonDialer::DrawItem(LPDRAWITEMSTRUCT lpDrawItemStruct)
{
	CDC dc;
	dc.Attach(lpDrawItemStruct->hDC);
	CRect rt(lpDrawItemStruct->rcItem);
	UINT state = lpDrawItemStruct->itemState;

	CString strTemp;
	GetWindowText(strTemp);

	COLORREF face = RGB(38, 50, 56);
	COLORREF hover = RGB(55, 71, 79);
	COLORREF pressed = RGB(20, 35, 40);

	if (strTemp == _T("1") || strTemp == _T("2") || strTemp == _T("3")) {
		face = RGB(0, 122, 255);
		hover = RGB(30, 144, 255);
		pressed = RGB(0, 92, 200);
	}
	else if (strTemp == _T("4") || strTemp == _T("5") || strTemp == _T("6")) {
		face = RGB(0, 166, 81);
		hover = RGB(24, 185, 101);
		pressed = RGB(0, 125, 61);
	}
	else if (strTemp == _T("7") || strTemp == _T("8") || strTemp == _T("9")) {
		face = RGB(255, 126, 0);
		hover = RGB(255, 145, 30);
		pressed = RGB(210, 95, 0);
	}

	if (state & ODS_DISABLED) {
		face = RGB(224, 224, 224);
		hover = face;
		pressed = face;
	}

	if (state & ODS_SELECTED) {
		dc.FillSolidRect(rt, pressed);
	}
	else if (GetCapture() == this) {
		dc.FillSolidRect(rt, hover);
	}
	else {
		dc.FillSolidRect(rt, face);
	}

	dc.SetBkMode(TRANSPARENT);
	COLORREF oldText = dc.SetTextColor((state & ODS_DISABLED) ? RGB(145, 145, 145) : RGB(255, 255, 255));

	int x12 = MulDiv(12, dpiY, 96);
	int x14 = MulDiv(14, dpiY, 96);
	int x4 = MulDiv(4, dpiY, 96);
	CRect rtl = rt;
	CString letters;

	if (!forceNumeric && m_map.Lookup(strTemp, letters)) {
		rtl.left += x14;
		dc.DrawText(strTemp, rtl, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
		HFONT hOldFont = (HFONT)SelectObject(dc.m_hDC, m_FontLetters);
		rtl.left += x12;
		rtl.right -= x4;
		dc.DrawText(letters, rtl, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
		SelectObject(dc.m_hDC, hOldFont);
	}
	else {
		dc.DrawText(strTemp, rt, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
	}

	dc.SetTextColor(oldText);
	if (state & ODS_FOCUS) {
		CRect focus = rt;
		focus.DeflateRect(3, 3);
		dc.DrawFocusRect(focus);
	}
	dc.Detach();
}
