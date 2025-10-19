<?php

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__)
    ->name('*.php')
    ->ignoreDotFiles(true)
    ->ignoreVCS(true);

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
        '@Symfony' => true,
        'array_syntax' => ['syntax' => 'short'],
        'binary_operator_spaces' => [
            'default' => 'single_space',
        ],
        'blank_line_after_opening_tag' => false, // Не добавлять пустую строку после <?php
        'concat_space' => ['spacing' => 'one'],
        'function_typehint_space' => true,
        'single_quote' => true,
        'trailing_comma_in_multiline' => ['elements' => ['arrays']],
        'no_unused_imports' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'phpdoc_align' => ['align' => 'left'],
        'phpdoc_indent' => true,
        'phpdoc_no_package' => true,
        'phpdoc_scalar' => true,
        'phpdoc_summary' => true,
        'phpdoc_to_comment' => true,
        'phpdoc_trim' => true,
        'indentation_type' => true,
        'no_extra_blank_lines' => true,
        'no_trailing_whitespace' => true,
        'single_blank_line_at_eof' => true,
        'no_closing_tag' => false, // Разрешить закрывающий ?> тег
    ])
    ->setIndent('  ') // 2 spaces
    ->setLineEnding("\n")
    ->setFinder($finder);
