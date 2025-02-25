package skalii.restful.onaftdigestserver.repository


import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as EmptyRepository
import org.springframework.stereotype.Repository

import skalii.restful.onaftdigestserver.entity.Keyword


@Repository
interface KeywordsRepository : EmptyRepository<Keyword, Int> {

    @Query(value = """select (keyword_search(
                          cast_int(:id_keyword),
                          cast_text(:word)
                      )).*""",
            nativeQuery = true)
    fun findSome(
            @Param("id_keyword") idKeyword: Int? = null,
            @Param("word") word: String? = null
    ): MutableList<Keyword>

    @Query(value = """select (keyword_search(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Keyword>

    @Query(value = """select (keyword_insert(
                          cast_text(:#{#keyword.word})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("keyword") newKeyword: Keyword): Keyword

    @Query(value = """select (keyword_update(
                          cast_text(:#{#keyword.word}),
                          cast_int(:#{#keyword.idKeyword})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("keyword") newKeyword: Keyword): Keyword

    @Query(value = """select (keyword_delete(cast_int(:id_keyword))).*""",
            nativeQuery = true)
    fun remove(@Param("id_keyword") idKeyword: Int): Keyword

}