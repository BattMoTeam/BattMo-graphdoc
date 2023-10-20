# -*- coding: utf-8 -*-
#
# MATLAB Sphinx Documentation Test documentation build configuration file, created by
# sphinx-quickstart on Wed Jan 15 11:38:03 2014.
#
# This file is execfile()d with the current directory set to its
# containing dir.
#
# Note that not all possible configuration values are present in this
# autogenerated file.
#
# All configuration values have a default; values that are commented out
# serve to show the default.
from __future__ import unicode_literals
import sys
import os
import docutils
import errno
from docutils.parsers.rst import roles

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
sys.path.insert(0, os.path.abspath(os.path.join('..')))
matlab_src_dir = os.path.abspath('..')

autoclass_content = 'both'
autodoc_member_order = 'bysource'

# -- General configuration ------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = ['sphinxcontrib.globalsubs', 'sphinxcontrib.bibtex']
bibtex_bibfiles = ['refs.bib']

global_substitutions = {
    'battmo': '**BattMo**'
}
# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix of source filenames.
source_suffix = '.rst'

# The encoding of source files.
#source_encoding = 'utf-8-sig'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = 'BattMo'
copyright = '2021, Simon Clark'
author = 'Simon Clark'

# The version info for the project you're documenting, acts as replacement for
# |version| and |release|, also used in various other places throughout the
# built documents.
#
# The short X.Y version.
# version = '0.1'
# The full version, including alpha/beta/rc tags.
# release = '0.1'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#language = None

# There are two options for replacing |today|: either, you set today to some
# non-false value, then it is used:
#today = ''
# Else, today_fmt is used as the format for a strftime call.
#today_fmt = '%B %d, %Y'

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
exclude_patterns = ['_build']

# The reST default role (used for this markup: `text`) to use for all
# documents.
#default_role = None

# If true, '()' will be appended to :func: etc. cross-reference text.
#add_function_parentheses = True

# If true, the current module name will be prepended to all description
# unit titles (such as .. function::).
#add_module_names = True

# If true, sectionauthor and moduleauthor directives will be shown in the
# output. They are ignored by default.
#show_authors = False

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# A list of ignored prefixes for module index sorting.
#modindex_common_prefix = []

# If true, keep warnings as "system message" paragraphs in the built documents.
#keep_warnings = False


# -- Options for HTML output ----------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
html_theme = 'sphinx_rtd_theme'

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
html_theme_options = {
    # Toc options
    'collapse_navigation': False,
    'sticky_navigation': True,
    'navigation_depth': 4,
    'includehidden': True,
    'titles_only': False
    }

# Add any paths that contain custom themes here, relative to this directory.
#html_theme_path = []

# The name for this set of Sphinx documents.  If None, it defaults to
# "<project> v<release> documentation".
#html_title = None

# A shorter title for the navigation bar.  Default is the same as html_title.
#html_short_title = None

# The name of an image file (relative to this directory) to place at the top
# of the sidebar.
html_logo = 'battmologo.png'
html_favicon = 'battmologo.ico'

# The name of an image file (within the static path) to use as favicon of the
# docs.  This file should be a Windows icon file (.ico) being 16x16 or 32x32
# pixels large.
#html_favicon = None

rst_prolog = """
.. role:: todo
   :class: todo
"""

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']
html_css_files = ['css/custom.css']

# Add any extra paths that contain custom files (such as robots.txt or
# .htaccess) here, relative to this directory. These files are copied
# directly to the root of the documentation.
#html_extra_path = []

# If not '', a 'Last updated on:' timestamp is inserted at every page bottom,
# using the given strftime format.
#html_last_updated_fmt = '%b %d, %Y'

# If true, SmartyPants will be used to convert quotes and dashes to
# typographically correct entities.
#html_use_smartypants = True

# Custom sidebar templates, maps document names to template names.
#html_sidebars = {}

# Additional templates that should be rendered to pages, maps page names to
# template names.
#html_additional_pages = {}

# If false, no module index is generated.
#html_domain_indices = True

# If false, no index is generated.
#html_use_index = True

# If true, the index is split into individual pages for each letter.
#html_split_index = False

# If true, links to the reST sources are added to the pages.
#html_show_sourcelink = True

# If true, "Created using Sphinx" is shown in the HTML footer. Default is True.
#html_show_sphinx = True

# If true, "(C) Copyright ..." is shown in the HTML footer. Default is True.
#html_show_copyright = True

# If true, an OpenSearch description file will be output, and all pages will
# contain a <link> tag referring to it.  The value of this option must be the
# base URL from which the finished HTML is served.
#html_use_opensearch = ''

# This is the file name suffix for HTML files (e.g. ".xhtml").
#html_file_suffix = None

# Output file base name for HTML help builder.
# htmlhelp_basename = 'MATLABSphinxDocumentationTestdoc'


# -- Options for LaTeX output ---------------------------------------------

latex_elements = {
# The paper size ('letterpaper' or 'a4paper').
#'papersize': 'letterpaper',

# The font size ('10pt', '11pt' or '12pt').
#'pointsize': '10pt',

# Additional stuff for the LaTeX preamble.
#'preamble': '',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
  ('index', 'MATLABSphinxDocumentationTest.tex', 'MATLAB Sphinx Documentation Test Documentation',
   'Mark Mikofski', 'manual'),
]

# The name of an image file (relative to this directory) to place at the top of
# the title page.
#latex_logo = None

# For "manual" documents, if this is true, then toplevel headings are parts,
# not chapters.
#latex_use_parts = False

# If true, show page references after internal links.
#latex_show_pagerefs = False

# If true, show URL addresses after external links.
#latex_show_urls = False

# Documents to append as an appendix to all manuals.
#latex_appendices = []

# If false, no module index is generated.
#latex_domain_indices = True


# -- Options for manual page output ---------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
# man_pages = [
    # ('index', 'matlabsphinxdocumentationtest', 'MATLAB Sphinx Documentation Test Documentation',
     # ['Mark Mikofski'], 1)
# ]

# If true, show URL addresses after external links.
#man_show_urls = False


# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
# texinfo_documents = [
  # ('index', 'MATLABSphinxDocumentationTest', 'MATLAB Sphinx Documentation Test Documentation',
   # 'Mark Mikofski', 'MATLABSphinxDocumentationTest', 'One line description of project.',
   # 'Miscellaneous'),
# ]

# Documents to append as an appendix to all manuals.
#texinfo_appendices = []

# If false, no module index is generated.
#texinfo_domain_indices = True

# How to display URL addresses: 'footnote', 'no', or 'inline'.
#texinfo_show_urls = 'footnote'

# If true, do not generate a @detailmenu in the "Top" node's menu.
#texinfo_no_detailmenu = False
# napoleon_google_docstring = True
add_module_names=False
# autodoc_preserve_defaults = True

# from sphinxcontrib.mat_documenters import MatAttributeDocumenter, MatClassLevelDocumenter
# import sphinx

# def _add_directive_header(self, sig):
#     MatClassLevelDocumenter.add_directive_header(self, sig)
#     if not self.options.annotation:
#         if not self._datadescriptor:
#             try:
#                 objrepr = sphinx.util.inspect.object_description(self.object.default)  # display default
#             except ValueError:
#                 pass
#             else:
#                 self.add_line('   :annotation:', '<autodoc>')
#     elif self.options.annotation is SUPPRESS:
#         pass
#     else:
#         self.add_line('   :annotation: %s' % self.options.annotation,
#                       '<autodoc>')

# MatAttributeDocumenter.add_directive_header = _add_directive_header


repo_url = 'https://github.com/BattMoTeam/BattMo-dev'
branch_name = 'modelrefac'


def find_battmo_file(filename):
    ignored_dirs = ['output', 'MRST', '.git', 'Documentation']
    for root, dirs, files in os.walk(matlab_src_dir):
        for r in ignored_dirs:
            if r in dirs:
                dirs.remove(r)
        if filename in files:
            return os.path.join(os.path.relpath(root, matlab_src_dir),
                                filename)
    raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), filename)


def battmo_reference_role(role, rawtext, text, lineno, inliner,
                          options=None, content=None):
    if "#" in text:
        funcname, lineno = docutils.utils.unescape(text).split("#", 1)
    else:
        funcname, lineno = docutils.utils.unescape(text), None
    mfuncname = funcname + '.m'
    fullfuncname = find_battmo_file(mfuncname)
    ref = repo_url + '/blob/' + branch_name + '/' + fullfuncname
    if lineno is not None:
        ref += "#L"+lineno
    options = roles.normalized_role_options(options)
    node = docutils.nodes.reference(rawtext, str(funcname), refuri=ref,
                           **options)
    return [node], []


roles.register_local_role('battmo', battmo_reference_role)
