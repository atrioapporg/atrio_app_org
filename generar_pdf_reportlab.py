import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

# Paleta ATRIO
AZUL_FONDO = colors.HexColor('#072B4F')
AZUL_MEDIO = colors.HexColor('#0055A5')
AMARILLO_ORO = colors.HexColor('#E5A023')
BLANCO = colors.white
GRIS_FONDO = colors.HexColor('#F8FAFC')
GRIS_BORDE = colors.HexColor('#CBD5E1')
GRIS_TEXTO = colors.HexColor('#475569')
TEXTO_DARK = colors.HexColor('#0F172A')
VERDE_DARK = colors.HexColor('#166534')
VERDE_BG = colors.HexColor('#F0FDF4')
ROJO_DARK = colors.HexColor('#991B1B')
ROJO_BG = colors.HexColor('#FEF2F2')

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(GRIS_TEXTO)
        
        # Pie de página
        footer_text = "ATRIO • Plataforma Móvil y Portal de Gestión Eclesiástica (Odoo 19)"
        page_str = f"Página {self._pageNumber} de {page_count}"
        
        # Línea separadora de pie
        self.setStrokeColor(GRIS_BORDE)
        self.setLineWidth(0.5)
        self.line(36, 32, letter[0] - 36, 32)
        
        self.drawString(36, 20, footer_text)
        self.drawRightString(letter[0] - 36, 20, page_str)
        self.restoreState()

def generar_pdf():
    pdf_path = r"c:\APPS\ATRIO\Resumen_Permisos_Usuarios_ATRIO.pdf"
    
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=45
    )

    styles = getSampleStyleSheet()

    # Estilos de párrafo
    title_style = ParagraphStyle(
        'HeaderTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=BLANCO
    )
    
    subtitle_style = ParagraphStyle(
        'HeaderSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor('#E2E8F0')
    )
    
    meta_style = ParagraphStyle(
        'HeaderMeta',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        alignment=2,
        textColor=AMARILLO_ORO
    )

    role_title_style = ParagraphStyle(
        'RoleTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=15,
        textColor=AZUL_FONDO
    )
    
    role_creds_style = ParagraphStyle(
        'RoleCreds',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=AZUL_MEDIO
    )

    desc_style = ParagraphStyle(
        'RoleDesc',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=8.5,
        leading=11,
        textColor=GRIS_TEXTO
    )

    col_header_yes = ParagraphStyle(
        'ColHeaderYes',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=11,
        textColor=VERDE_DARK
    )

    col_header_no = ParagraphStyle(
        'ColHeaderNo',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=11,
        textColor=ROJO_DARK
    )

    item_yes_style = ParagraphStyle(
        'ItemYes',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=10.5,
        textColor=TEXTO_DARK
    )

    item_no_style = ParagraphStyle(
        'ItemNo',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=10.5,
        textColor=TEXTO_DARK
    )

    th_style = ParagraphStyle(
        'TableTH',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        alignment=1,
        textColor=BLANCO
    )

    td_style = ParagraphStyle(
        'TableTD',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=TEXTO_DARK
    )

    td_center = ParagraphStyle(
        'TableTDCenter',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=10.5,
        alignment=1
    )

    story = []

    # 1. ENCABEZADO BANNER
    header_content = [
        [
            Paragraph("<b>ATRIO</b> • Matriz de Roles y Permisos", title_style),
            Paragraph("Portal Odoo 19 + App Flutter 3.29<br/>https://atrioapp.odoo19rd.com", meta_style)
        ],
        [
            Paragraph("Resumen detallado de capacidades y restricciones por perfil de usuario", subtitle_style),
            Paragraph("Fecha: Octubre 2026 • Documento Oficial", ParagraphStyle('submeta', parent=meta_style, fontName='Helvetica', textColor=BLANCO))
        ]
    ]
    t_header = Table(header_content, colWidths=[360, 180])
    t_header.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), AZUL_FONDO),
        ('PADDING', (0, 0), (-1, -1), 10),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 2),
        ('TOPPADDING', (0, 1), (-1, 1), 2),
    ]))
    story.append(t_header)
    story.append(Spacer(1, 12))

    # Helper para crear bloques de usuario
    def build_user_card(num_str, title, creds, desc, yes_items, no_items, border_color):
        header_table = Table([
            [
                Paragraph(f"{num_str}. {title}", role_title_style),
                Paragraph(creds, role_creds_style)
            ]
        ], colWidths=[290, 250])
        header_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('PADDING', (0, 0), (-1, -1), 0),
            ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
        ]))

        yes_content = [Paragraph("<b>LO QUE SÍ PUEDE HACER:</b>", col_header_yes), Spacer(1, 4)]
        for item in yes_items:
            yes_content.append(Paragraph(f"• {item}", item_yes_style))
            yes_content.append(Spacer(1, 2))

        no_content = [Paragraph("<b>LO QUE NO PUEDE HACER:</b>", col_header_no), Spacer(1, 4)]
        for item in no_items:
            no_content.append(Paragraph(f"• {item}", item_no_style))
            no_content.append(Spacer(1, 2))

        cols_table = Table([
            [yes_content, no_content]
        ], colWidths=[262, 262])
        cols_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, 0), VERDE_BG),
            ('BACKGROUND', (1, 0), (1, 0), ROJO_BG),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('PADDING', (0, 0), (-1, -1), 8),
            ('BOX', (0, 0), (0, 0), 0.5, colors.HexColor('#BBF7D0')),
            ('BOX', (1, 0), (1, 0), 0.5, colors.HexColor('#FECACA')),
        ]))

        card_wrapper = Table([
            [header_table],
            [Paragraph(desc, desc_style)],
            [cols_table]
        ], colWidths=[540])
        card_wrapper.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), GRIS_FONDO),
            ('BOX', (0, 0), (-1, -1), 1, border_color),
            ('PADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, 0), 6),
            ('BOTTOMPADDING', (0, 1), (-1, 1), 4),
        ]))
        return KeepTogether([card_wrapper, Spacer(1, 10)])

    # 1. Modo Invitado
    story.append(build_user_card(
        "1",
        "Modo Invitado",
        "Sin autenticación / Navegación libre",
        "Usuario que explora la aplicación sin registrarse ni iniciar sesión.",
        [
            "Lectura completa de la Santa Biblia y reproducción de audiolibros.",
            "Sintonizar emisoras de radio cristiana en vivo y ver videos/transmisiones.",
            "Explorar directorio de iglesias públicas y perfiles generales.",
            "Consultar catálogo de la Tienda Atrio y fechas de eventos públicos."
        ],
        [
            "<b>No puede donar</b> (bloqueado por diálogo de inicio de sesión requerido).",
            "<b>No puede enviar peticiones de oración</b> ni solicitudes pastorales.",
            "<b>Sin historial</b> de solicitudes ni donaciones (pantalla vacía invitando al login).",
            "<b>No puede comprar en la tienda</b> (checkout requiere cuenta).",
            "No puede inscribirse a eventos ni recibe notificaciones personalizadas.",
            "<b>Sin acceso alguno al Portal Administrativo de Odoo</b>."
        ],
        colors.HexColor('#94A3B8')
    ))

    # 2. Miembro de una Iglesia
    story.append(build_user_card(
        "2",
        "Miembro de una Iglesia",
        "leningrado777@demo.app | Clave: 123456",
        "Feligrés activo con congregación asignada en Odoo (rol: member).",
        [
            "Todo lo permitido al usuario invitado.",
            "<b>Enviar solicitudes pastorales</b>: Petición de oración, consejería familiar, orientación, etc.",
            "<b>Seguimiento e historial de solicitudes</b>: Estados en vivo (Recibida, En proceso, Respondida) con notas pastorales.",
            "<b>Donar y ofrendar</b> con PayPal o transferencia (adjuntando comprobante).",
            "<b>Historial y recibos de donaciones</b> realizados por el usuario.",
            "<b>Compras en Tienda Atrio</b>: Carrito, confirmación de orden y pedidos.",
            "Inscripción activa a eventos de su congregación y gestión de perfil."
        ],
        [
            "<b>No accede a 'Administración Pastoral'</b> en la app (oculto por PermissionGuard).",
            "No puede publicar ni eliminar avisos congregacionales.",
            "No puede moderar peticiones de oración de otros miembros.",
            "No puede ver estadísticas ni métricas de la comunidad.",
            "No puede crear campañas de anuncios publicitarios de iglesia.",
            "<b>Sin acceso a la consola de administración de Odoo</b>."
        ],
        AZUL_MEDIO
    ))

    # 3. Admin de Iglesia
    story.append(build_user_card(
        "3",
        "Administrador de una Iglesia",
        "admin.atrio@demo.app | Clave: admin",
        "Pastor o líder administrativo de su congregación local (rol: church_admin).",
        [
            "Todas las funciones operativas de un Miembro activo.",
            "<b>Acceso exclusivo a 'Administración Pastoral'</b> en la App Móvil:",
            "• <b>Avisos congregacionales</b>: Redactar, segmentar por grupos y fijar avisos.",
            "• <b>Audiencias y grupos</b>: Consultar y gestionar audiencias para avisos.",
            "• <b>Moderación de peticiones</b>: Aprobar o rechazar peticiones de oración.",
            "• <b>Estadísticas de comunidad</b>: Métricas analíticas semanales, mensuales y anuales.",
            "• <b>Publicidad de iglesia</b>: Cotizar, crear y enviar a revisión anuncios locales.",
            "<b>Acceso a Odoo</b>: Administra los registros correspondientes a su propia iglesia."
        ],
        [
            "<b>No puede gestionar iglesias ajenas</b> (restringido estrictamente a su church_id).",
            "No puede crear ni eliminar congregaciones globales en ATRIO.",
            "No puede ver datos financieros, ventas ni donaciones de otras iglesias.",
            "No puede aprobar campañas de anuncios de otras congregaciones.",
            "No puede alterar la configuración técnica global de la plataforma."
        ],
        AMARILLO_ORO
    ))

    # 4. Superadmin Portal
    story.append(build_user_card(
        "4",
        "Superadmin del Portal (Plataforma Global)",
        "leningrado777@gmail.com | Clave: leningrado777@gmail",
        "Root / Propietario general del sistema ATRIO (rol: platform_admin / Superuser).",
        [
            "<b>Control absoluto del Portal Web Odoo (Action-700)</b>:",
            "• <b>Gestión global de iglesias</b>: Alta, baja, aprobación y configuración de planes.",
            "• <b>Gestión integral de usuarios</b>: Administradores de iglesia y miembros de todo el ecosistema.",
            "• <b>Aprobación final de publicidad</b>: Audita y activa anuncios de iglesias.",
            "• <b>Reportes financieros globales</b>: Monitoreo de todas las donaciones y ventas.",
            "• <b>Configuración técnica Odoo</b>: Módulos, flujos y arquitectura REST API.",
            "En la app móvil cuenta con visibilidad y permisos de auditoría institucional."
        ],
        [
            "En la app móvil actúa bajo perfil de plataforma; para donar u ofrendar como feligrés local, el sistema valida que cuente con una congregación asignada activa (hasChurchAssigned)."
        ],
        AZUL_FONDO
    ))

    # MATRIZ COMPARATIVA
    story.append(KeepTogether([
        Paragraph("<b>MATRIZ COMPARATIVA DE CAPACIDADES Y ACCESOS</b>", ParagraphStyle('SecTitle', parent=role_title_style, fontSize=11, leading=14)),
        Spacer(1, 6)
    ]))

    matrix_data = [
        [
            Paragraph("<b>Módulo / Capacidad</b>", th_style),
            Paragraph("<b>Invitado</b>", th_style),
            Paragraph("<b>Miembro</b>", th_style),
            Paragraph("<b>Admin Iglesia</b>", th_style),
            Paragraph("<b>Superadmin Portal</b>", th_style),
        ],
        [
            Paragraph("Lectura Biblia, Audios y Radio Cristiana", td_style),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
        ],
        [
            Paragraph("Enviar Solicitudes y Peticiones Pastorales", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("Auditoría / Odoo", td_center),
        ],
        [
            Paragraph("Historial y Seguimiento de Solicitudes", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("Auditoría / Odoo", td_center),
        ],
        [
            Paragraph("Donar y Ofrendar (PayPal / Transferencia)", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("Auditoría / Odoo", td_center),
        ],
        [
            Paragraph("Historial de Donaciones y Comprobantes", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("Todas las iglesias", td_center),
        ],
        [
            Paragraph("Compras en Tienda Atrio (Checkout)", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("Auditoría / Odoo", td_center),
        ],
        [
            Paragraph("Inscripción a Eventos de Congregación", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ</b></font>", td_center),
            Paragraph("Auditoría / Odoo", td_center),
        ],
        [
            Paragraph("Publicar Avisos Congregacionales en la App", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ (Su iglesia)</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ (Global)</b></font>", td_center),
        ],
        [
            Paragraph("Moderar Peticiones de Oración", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ (Su iglesia)</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ (Global)</b></font>", td_center),
        ],
        [
            Paragraph("Ver Estadísticas de Comunidad", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ (Su iglesia)</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>SÍ (Todas)</b></font>", td_center),
        ],
        [
            Paragraph("Pautar Anuncios de Iglesia", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#0055A5'><b>Cotiza / Crea</b></font>", td_center),
            Paragraph("<font color='#16a34a'><b>Aprueba / Audita</b></font>", td_center),
        ],
        [
            Paragraph("Acceso al Portal Web Odoo (Backend ERP)", td_style),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#dc2626'><b>NO</b></font>", td_center),
            Paragraph("<font color='#475569'>Su iglesia</font>", td_center),
            Paragraph("<font color='#072B4F'><b>Control Total</b></font>", td_center),
        ],
    ]

    t_matrix = Table(matrix_data, colWidths=[180, 70, 75, 105, 110])
    t_matrix.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), AZUL_FONDO),
        ('GRID', (0, 0), (-1, -1), 0.5, GRIS_BORDE),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('PADDING', (0, 0), (-1, -1), 4),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [BLANCO, colors.HexColor('#F8FAFC')]),
    ]))

    story.append(KeepTogether([t_matrix]))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generado con éxito en: {pdf_path}")
    print(f"Tamaño del archivo: {os.path.getsize(pdf_path)} bytes")

if __name__ == '__main__':
    generar_pdf()
