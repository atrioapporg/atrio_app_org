# -*- coding: utf-8 -*-
"""
Generador del manual / guía PDF en alta resolución:
"Guía Paso a Paso: Transmisiones en Vivo de YouTube en ATRIO"
Canal: @FontAndon
"""

import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, HRFlowable, ListFlowable, ListItem
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY


class NumberedCanvas(canvas.Canvas):
    """Canvas de dos pasadas para calcular automáticamente el total de páginas."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_elements(num_pages)
            super().showPage()
        super().save()

    def draw_page_elements(self, page_count):
        self.saveState()
        
        # En la primera página no dibujamos el header superior repetido
        if self._pageNumber > 1:
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#1E3A8A"))
            self.drawString(40, 760, "ATRIO")
            self.setFont("Helvetica", 8)
            self.setFillColor(colors.HexColor("#64748B"))
            self.drawString(75, 760, "|  Guía de Transmisiones en Vivo con YouTube")
            self.drawRightString(572, 760, "Canal: @FontAndon")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.6)
            self.line(40, 752, 572, 752)

        # Footer en todas las páginas
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.6)
        self.line(40, 44, 572, 44)

        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#1E293B"))
        self.drawString(40, 32, "ATRIO Church Platform")
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(135, 32, "• Guía Operativa para Administradores y Pastores")

        page_str = f"Página {self._pageNumber} de {page_count}"
        self.drawRightString(572, 32, page_str)
        self.restoreState()


def create_callout(text, title="NOTA IMPORTANTE", bg_color="#EFF6FF", border_color="#3B82F6", text_color="#1E3A8A", styles=None):
    """Crea una caja destacada tipo alerta moderna."""
    title_style = ParagraphStyle(
        'CalloutTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=12,
        textColor=colors.HexColor(text_color),
        spaceAfter=3,
    )
    body_style = ParagraphStyle(
        'CalloutBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11.5,
        textColor=colors.HexColor("#1F2937"),
    )

    content = [
        Paragraph(title, title_style),
        Paragraph(text, body_style)
    ]
    
    t = Table([[content]], colWidths=[532])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor(bg_color)),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor(border_color)),
        ('LINELEFT', (0,0), (0,0), 3.5, colors.HexColor(border_color)),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    return t


def build_pdf(filename="Guia_Transmisiones_YouTube_ATRIO.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=40,
        rightMargin=40,
        topMargin=46,
        bottomMargin=50
    )

    styles = getSampleStyleSheet()

    # Estilos personalizados
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#0F172A"),
        spaceAfter=4,
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=14,
        textColor=colors.HexColor("#475569"),
        spaceAfter=10,
    )

    badge_style = ParagraphStyle(
        'BadgeText',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#FFFFFF"),
        alignment=TA_CENTER
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=15,
        textColor=colors.HexColor("#1E3A8A"),
        spaceBefore=12,
        spaceAfter=5,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=13,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=8,
        spaceAfter=3,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12.5,
        textColor=colors.HexColor("#334155"),
        spaceAfter=5,
    )

    code_style = ParagraphStyle(
        'Code_Custom',
        parent=styles['Normal'],
        fontName='Courier-Bold',
        fontSize=8,
        leading=10.5,
        textColor=colors.HexColor("#0F172A"),
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#FFFFFF"),
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor("#1E293B"),
    )

    story = []

    # 1. ENCABEZADO Y PORTADA
    story.append(Paragraph("GUÍA PRÁCTICA DE TRANSMISIONES EN VIVO", ParagraphStyle('SubSub', fontName='Helvetica-Bold', fontSize=9, textColor=colors.HexColor("#DC2626"), leading=11, spaceAfter=2)))
    story.append(Paragraph("YouTube Live en ATRIO: Guía Paso a Paso", title_style))
    story.append(Paragraph("Configuración completa desde tu canal de YouTube hasta la reproducción en la aplicación móvil de ATRIO.", subtitle_style))

    # Ficha técnica del canal
    ficha_data = [
        [
            Paragraph("<b>Canal Oficial:</b> @FontAndon", table_cell_style),
            Paragraph("<b>Ubicación:</b> República Dominicana", table_cell_style),
            Paragraph("<b>Suscriptores:</b> 10 suscriptores", table_cell_style),
        ],
        [
            Paragraph("<b>Enlace Canal:</b> youtube.com/@FontAndon", table_cell_style),
            Paragraph("<b>Antigüedad:</b> Desde julio de 2010", table_cell_style),
            Paragraph("<b>Estado Streaming:</b> Apto vía PC / OBS", table_cell_style),
        ]
    ]
    t_ficha = Table(ficha_data, colWidths=[185, 175, 172])
    t_ficha.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F1F5F9")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_ficha)
    story.append(Spacer(1, 8))

    # Caja: Entendiendo la Arquitectura
    story.append(create_callout(
        "<b>¿Cómo se complementan YouTube y ATRIO?</b> ATRIO no hospeda directamente los gigabytes de las transmisiones en vivo para no sobrecargar el servidor ni cobrar costos excesivos a la iglesia. En su lugar, YouTube se encarga de la infraestructura de emisión masiva, calidad 1080p y codificación, mientras que <b>ATRIO ofrece un reproductor integrado y amigable</b> para los miembros de tu congregación dentro de la app móvil.",
        title="ARQUITECTURA DE FUNCIONAMIENTO",
        bg_color="#FEF2F2",
        border_color="#EF4444",
        text_color="#991B1B",
        styles=styles
    ))
    story.append(Spacer(1, 8))

    # ETAPA 1
    story.append(Paragraph("ETAPA 1: Preparación y Habilitación del Canal en YouTube", h1_style))
    story.append(Paragraph(
        "Existe una confusión común acerca de si se necesitan 50 o 1,000 suscriptores para emitir en vivo. La regla oficial de YouTube es muy clara y favorable para tu canal:",
        body_style
    ))

    reglas_data = [
        [
            Paragraph("<b>Dispositivo de Emisión</b>", table_header_style),
            Paragraph("<b>Requisito de Suscriptores</b>", table_header_style),
            Paragraph("<b>Situación para tu Canal @FontAndon</b>", table_header_style),
        ],
        [
            Paragraph("<b>Computadora (PC / Laptop)</b><br/>Vía Cámara Web o navegador", table_cell_style),
            Paragraph("<b>0 suscriptores</b> (Sin mínimo).", table_cell_style),
            Paragraph("<font color='#059669'><b>¡100% DISPONIBLE AHORA!</b></font>", table_cell_style),
        ],
        [
            Paragraph("<b>Programa de Emisión (OBS Studio)</b><br/>Consola, cámaras externas, diapositivas", table_cell_style),
            Paragraph("<b>0 suscriptores</b> (Sin mínimo).", table_cell_style),
            Paragraph("<font color='#059669'><b>¡100% DISPONIBLE AHORA!</b></font>", table_cell_style),
        ],
        [
            Paragraph("<b>App Móvil de YouTube en Celular</b><br/>Transmitir directo desde el celular", table_cell_style),
            Paragraph("<b>50 suscriptores mínimo</b>.", table_cell_style),
            Paragraph("<font color='#DC2626'><b>No disponible aún</b> (Tienes 10 subs).</font>", table_cell_style),
        ],
    ]
    t_reglas = Table(reglas_data, colWidths=[185, 175, 172])
    t_reglas.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#1E3A8A")),
        ('BACKGROUND', (0,1), (-1,1), colors.HexColor("#FFFFFF")),
        ('BACKGROUND', (0,2), (-1,2), colors.HexColor("#F8FAFC")),
        ('BACKGROUND', (0,3), (-1,3), colors.HexColor("#FFFFFF")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_reglas)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Pasos para activar directos por primera vez:</b>", h2_style))
    story.append(Paragraph("1. Ingresa a <b>https://studio.youtube.com/</b> con tu cuenta.", body_style))
    story.append(Paragraph("2. Ve a <b>Configuración</b> (engranaje) ➔ <b>Canal</b> ➔ <b>Acceso a funciones</b>. Asegúrate de verificar tu número telefónico dominicano por SMS.", body_style))
    story.append(Paragraph("3. Haz clic en el botón rojo <b>Crear</b> (arriba a la derecha) y pulsa <b>Transmitir en vivo</b>.", body_style))
    story.append(Paragraph("4. Si nunca habías transmitido, YouTube iniciará una activación de seguridad que toma <b>hasta 24 horas</b>. Una vez concluido, el canal queda desbloqueado indefinidamente.", body_style))
    story.append(Spacer(1, 6))

    # ETAPA 2
    story.append(Paragraph("ETAPA 2: Cómo Iniciar la Transmisión en YouTube", h1_style))
    story.append(Paragraph("Tienes dos alternativas recomendadas desde tu computadora:", body_style))

    story.append(Paragraph("<b>Opción A: Desde el Navegador Web (Cámara Web / Laptop)</b>", h2_style))
    story.append(Paragraph("• En YouTube Studio, pulsa <b>Transmitir en vivo</b> y selecciona el icono de <b>Cámara web</b>.<br/>"
                           "• Ingresa el título (ej: <i>Culto en Vivo - @FontAndon</i>).<br/>"
                           "• En <b>Visibilidad</b>, selecciona <b>Público</b> o <b>No listado / Oculto</b> (¡Nunca <i>Privado</i>, ya que los miembros no podrán reproducirlo en ATRIO!).<br/>"
                           "• Marca: <i>'No, no es contenido para niños'</i> (esto asegura que el chat y comentarios funcionen con normalidad).<br/>"
                           "• Haz clic en <b>Transmitir en vivo</b>.", body_style))

    story.append(Paragraph("<b>Opción B: Transmisión Avanzada con OBS Studio</b>", h2_style))
    story.append(Paragraph("• Descarga <b>OBS Studio</b> en tu computadora (software libre y gratuito).<br/>"
                           "• En YouTube Studio, pestaña <b>Emitir</b>, copia tu <b>Clave de emisión</b> privada.<br/>"
                           "• En OBS, ve a <i>Ajustes ➔ Emisión ➔ Servicio: YouTube RTMPS</i> y pega tu clave.<br/>"
                           "• Agrega tus fuentes de cámara, capturas y micrófono, y pulsa <b>Iniciar transmisión</b>.", body_style))
    story.append(Spacer(1, 6))

    # ETAPA 3
    story.append(Paragraph("ETAPA 3: Obtener el Enlace de la Transmisión para ATRIO", h1_style))
    story.append(Paragraph(
        "ATRIO cuenta con un analizador inteligente (<b>YoutubeHelper</b>) que reconoce dos tipos de enlaces de tu canal:",
        body_style
    ))

    enlaces_data = [
        [
            Paragraph("<b>Tipo de Enlace</b>", table_header_style),
            Paragraph("<b>Formato de la URL</b>", table_header_style),
            Paragraph("<b>Uso Recomendado en ATRIO</b>", table_header_style),
        ],
        [
            Paragraph("<b>Enlace Permanente de Canal</b><br/><i>(El más cómodo)</i>", table_cell_style),
            Paragraph("<b>https://www.youtube.com/@FontAndon/live</b>", code_style),
            Paragraph("<b>Excelente:</b> No necesitas cambiar el link cada domingo. Siempre que transmitas en tu canal, ATRIO lo reproducirá.", table_cell_style),
        ],
        [
            Paragraph("<b>Enlace Específico del Video</b><br/><i>(Transmisión programada)</i>", table_cell_style),
            Paragraph("<b>https://youtube.com/live/ID_VIDEO</b><br/>o watch?v=ID_VIDEO", code_style),
            Paragraph("<b>Ideal:</b> Cuando programas una prédica con fecha/hora específica y miniatura personalizada previa.", table_cell_style),
        ],
    ]
    t_enlaces = Table(enlaces_data, colWidths=[130, 245, 157])
    t_enlaces.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0F172A")),
        ('BACKGROUND', (0,1), (-1,1), colors.HexColor("#F0FDF4")),
        ('BACKGROUND', (0,2), (-1,2), colors.HexColor("#FFFFFF")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_enlaces)
    story.append(Spacer(1, 8))

    # ETAPA 4
    story.append(Paragraph("ETAPA 4: Publicar el Enlace en la Aplicación ATRIO", h1_style))
    story.append(Paragraph("1. Inicia sesión en la aplicación ATRIO con tu usuario administrador pastoral (rol <i>church_admin</i>).", body_style))
    story.append(Paragraph("2. Navega a la pantalla <b>Crear Prédica / Transmisión</b> (<i>crear_predica_screen.dart</i>).", body_style))
    story.append(Paragraph("3. Completa los campos básicos: Título, Predicador y Categoría (marca <b>'En vivo'</b> o <b>'Prédicas'</b>).", body_style))
    story.append(Paragraph("4. Activa el interruptor: <b>¿Es transmisión en vivo? = SÍ</b>.", body_style))
    story.append(Paragraph("5. Pega la URL en el campo <b>'Enlace de Transmisión (YouTube Live)'</b>. La app mostrará de inmediato una tarjeta con el badge verde:", body_style))

    badge_table = Table([[
        Paragraph("<font color='#059669'><b>✔ Video / Canal de YouTube Reconocido:</b> https://www.youtube.com/@FontAndon/live</font>", table_cell_style)
    ]], colWidths=[532])
    badge_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#ECFDF5")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#10B981")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(badge_table)
    story.append(Spacer(1, 5))
    story.append(Paragraph("6. Pulsa <b>Guardar / Publicar</b>. La transmisión quedará disponible al instante en el catálogo.", body_style))
    story.append(Spacer(1, 6))

    # ETAPA 5
    story.append(Paragraph("ETAPA 5: Experiencia del Miembro y Grabación Automática", h1_style))
    story.append(Paragraph(
        "• <b>En Vivo en la App:</b> Los miembros que abran la sección <b>Videos y Transmisiones</b> verán el banner con la insignia roja parpadeante <b>EN VIVO</b> y podrán pulsar para abrir el reproductor modal embebido con controles completos.<br/>"
        "• <b>Grabación Automática (VOD):</b> Al terminar la transmisión en YouTube Studio / OBS, YouTube procesa y guarda automáticamente el video. <b>No tienes que hacer nada en ATRIO:</b> el mismo enlace continuará funcionando para que los hermanos que no pudieron conectarse en directo vean la prédica grabada.",
        body_style
    ))
    story.append(Spacer(1, 8))

    # Checklist Final
    story.append(create_callout(
        "<b>1.</b> Canal @FontAndon verificado con SMS telefónico.<br/>"
        "<b>2.</b> Transmisión iniciada desde PC/Laptop (vía Cámara Web o OBS Studio).<br/>"
        "<b>3.</b> Visibilidad configurada como <b>Público</b> o <b>No listado</b> (Nunca Privado).<br/>"
        "<b>4.</b> Enlace pegado en ATRIO: <code>https://www.youtube.com/@FontAndon/live</code> o enlace del video.<br/>"
        "<b>5.</b> Transmisión publicada y lista para que la congregación se conecte.",
        title="CHECKLIST RÁPIDO ANTES DE INICIAR CULTO",
        bg_color="#F8FAFC",
        border_color="#64748B",
        text_color="#1E293B",
        styles=styles
    ))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generado exitosamente en: {filename}")


if __name__ == '__main__':
    output_filename = "Guia_Transmisiones_YouTube_ATRIO.pdf"
    if len(sys.argv) > 1:
        output_filename = sys.argv[1]
    build_pdf(output_filename)
